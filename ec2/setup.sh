#!/usr/bin/env bash
# Setup an AWS EC2 instance for running the 3DAdapt server
# This script is intended to be run on an Amazon Linux 2023 instance
# It installs all the necessary packages and sets up the environment

# Command line arguments:
#   -b: background worker (install OpenSCAD, fonts, F3D, and other libraries)
#   -s: server (install the web server and gateways)
#   -r: redis (install Redis)
#   -a: all (install everything) [default]
#
#   -R: repo to clone, default is https://github.com/MoravianUniversity/3DAdapt.git
#
#   -p: HTTP/S3 URL to download packages from (background worker only)
#       default: https://github.com/MoravianUniversity/3DAdapt-AWS-Setup/raw/main/packages
#   -c: HTTP/S3 URL to download config.py from, default requires you to add/edit it manually
#
#   -s: SSL certificate generation method (server only), one of:
#       route53 (use AWS Route 53, requires hosted zone and IAM permissions on EC2 instance)
#       http (use HTTP challenge, requires nginx to be configured properly)
#       HTTP/S3 URL (downloads a pre-generated certificate tarball, extracts to /etc)
#       cf:xxxx (use Cloudflare DNS, requires API token with Zone:DNS:Edit permission after the colon)
#       [if not provided you will need to manually add the certificates if desired]
#   -w: number of workers for gunicorn (rec between 2*N+1 and 4*N, 4-12 can handle hundreds to
#       thousands of requests/second), default is 3*N where N is the number of CPUs (server only)

# If not running on a real EC2 instance, you likely want to run aws configure before running this
# script so that you can access AWS resources like S3 buckets and Route 53.

# Get the command line arguments
background_worker=false
server=false
redis=false
repo="https://github.com/MoravianUniversity/3DAdapt.git"
source="https://github.com/MoravianUniversity/3DAdapt-AWS-Setup/raw/main/packages"
scripts="https://github.com/MoravianUniversity/3DAdapt-AWS-Setup/raw/main/ec2"  # no command line arg to change
config_url=""
ssl_method=""
workers=$(($(nproc) * 3))
while getopts "bsraR:p:c:s:w:" opt; do
  case $opt in
    b) background_worker=true ;;
    s) server=true ;;
    r) redis=true ;;
    a) background_worker=true; server=true; redis=true ;;
      R) repo="$OPTARG" ;;
    p) source="$OPTARG" ;;
      c) config_url="$OPTARG" ;;
    s) ssl_method="$OPTARG" ;;
      w) workers="$OPTARG" ;;
    *) echo "Invalid option: -$opt" >&2; exit 1 ;;
  esac
done
if [ "$background_worker" = false ] && [ "$server" = false ] && [ "$redis" = false ]; then
  background_worker=true
  server=true
  redis=true
fi
export source  # used by sub-scripts


# Helper functions to download files from either HTTP or S3
function download() {
  uri="$1"
  output="$2"
  [ -z "$output" ] && output="$(basename "$uri")"
  if [[ "$uri" =~ ^s3 ]]; then
    aws s3 cp "$uri" "$output" --no-progress || return 1
  else
    wget -nv -O "$output" "$uri" || return 1
  fi
}
function download_and_install() {
  # Download a file from $scripts then moves as root; default moves to /etc/systemd/system/$1
  file="$1"
  [ -z "$2" ] && dest="/etc/systemd/system/$file" || dest="$2"
  temp=$(mktemp)
  download "$scripts/$file" "$temp" && sudo mv "$temp" "$dest" || return 1
  sudo chown root:root "$dest"
  sudo chmod 644 "$dest"
}
function download_and_extract() {
  # Download a file from $source then extracts as root; default extracts to /usr/local
  file="$1"
  [ -z "$2" ] && dest="/usr/local" || dest="$2"
  download "$source/$file" "$file" && sudo tar -xvzf "$file" --no-same-owner -C "$dest"
}


##### Install System Packages #####
# Packages needed on all machines
sudo dnf install -y git python3.11 python3.11-pip

# Packages for specific depolyments
$server && sudo dnf install -y nginx
$redis && sudo dnf install -y redis6
$background_worker && sudo dnf install -y \
  xorg-x11-server-Xorg xorg-x11-server-Xvfb glew freeglut libglvnd-opengl mesa-libOSMesa mesa-libGLU libXmu \
  freetype fontconfig harfbuzz cairo \
  boost-system boost-filesystem boost-regex boost-program-options python3-pybind11 libffi \
  gmp-c++ mpfr tbb libxml2 expat jsoncpp glib2 libjpeg-turbo libtiff libpng libzip zlib xz lz4


##### Install Third Party Packages #####
# See ec2/amazon-linux-compile/*.sh for compiling these.
# Only needed on the background worker
if $background_worker; then
  tools=("double-conversion-3.3.0" "openscad" "openctm-1.0.3" "draco_decoder-1.5.7" "vtk-9.3.0" "f3d-2.4.0")
  for tool in "${tools[@]}"; do
    download_and_extract "$tool-$(arch)-linux-gnu.tar.gz"
  done
  # Update library cache
  echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/local.conf &>/dev/null
  echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/local.conf &>/dev/null
  sudo ldconfig
fi

# Install OpenSCAD fonts and libraries on the background worker
# See ec2/fonts.sh and ec2/openscad-libs.sh for more information
if $background_worker; then
  download_and_extract "openscad-libraries.tar.gz" "/usr/local/share/openscad/libraries/"
  download "$scripts/fonts.sh" && bash fonts.sh
fi


##### Clone Repo #####
# Supports HTTPS or SSH urls
# If SSH make sure to add the keys to the system first
# Private repos only work with SSH urls
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" \
    git clone "$repo" || exit 1


##### Setup the Server #####
cd 3DAdapt/server
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade wheel  # Flask-Mail requires this to be installed first to avoid warnings
pip install -r requirements-base.txt  # TODO: likely not all of these are needed for all deployments
pip install -r requirements-optional.txt  # TODO: same as above
$server && pip install gunicorn  # gunicorn WSGI server
pip cache purge  # clean up pip cache

# Link to third party tools just in case
if $background_worker; then
  mkdir -p third-party/bin third-party/lib
  ln -sf /usr/local/bin/draco_decoder third-party/bin
  ln -sf /usr/local/lib64/libopenctm.so third-party/lib
  ln -sf /usr/local/bin/openscad third-party/bin
  ln -sf openscad third-party/bin/openscad-nightly
  ln -sf /usr/local/bin/f3d third-party/bin
  ln -sf /usr/local/lib64/libf3d.so third-party/lib
  mkdir -p venv/lib64/python3.11/site-packages
  ln -sf /usr/local/lib64/python3.11/site-packages/f3d venv/lib64/python3.11/site-packages  # TODO: library crashes on import
fi


##### Configuration File #####
no_config=false
if ! [ -z "$config_url" ]; then
  download $config_url
elif ! [ -f "config.py" ]; then
  no_config=true
  cat >config.py <<EOF
from .config_default import *

# TODO: setup up configuration
EOF
fi


##### Setup Certificates #####
if $server; then
  function setup_certbot() {
    # Install prerequisites and setup virtual environment
    sudo dnf install -y augeas-libs
    sudo rm -rf /opt/certbot/  # reinstall
    sudo python3 -m venv /opt/certbot/
    sudo /opt/certbot/bin/pip install --upgrade pip

    # Install certbot
    local arg=""
    [ -n "$1" ] && arg="certbot-dns-$1"
    sudo /opt/certbot/bin/pip install certbot certbot-nginx $arg
    sudo ln -sf /opt/certbot/bin/certbot /usr/bin/certbot

    # Install timer
    # TODO: remove previous entry if it exists
    echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random, time; time.sleep(random.random() * 3600)' && sudo certbot renew -q" | sudo tee -a /etc/crontab > /dev/null

    # Get information needed for running certbot
    email="$(cd .. && python3 -c "import server.config; print(server.config.CONTACT_RECIPIENT)")"
    download "$scripts/nginx.conf" "$HOME/nginx.conf"
    domains=($(grep '^ *server_name' "$HOME/nginx.conf" | sed 's/^ *server_name \+//' | sed 's/[;#].*$//'))
    domain_args=()
    for d in "${domains[@]}"; do domain_args+=( "-d" "$d" ); done
    domain="${domains[0]}"
  }

  function run_certbot() {
    # Run certbot
    sudo certbot certonly -m "$email" --agree-tos -n -i nginx "$@" "${domain_args[@]}"
  }

  if [ "$ssl_method" = "route53" ]; then
    setup_certbot route-53 && \
      run_certbot --dns-route53 --dns-route53-propagation-seconds 20
  elif [[ "$ssl_method" == "cf:"* ]]; then  # Cloudflare DNS with API token
    setup_certbot cloudflare
    api_token="${ssl_method#cf:}"
    conf="/etc/letsencrypt/tokens/cloudflare-$domain.ini"
    sudo mkdir -m 700 -p "$(dirname "$conf")"
    echo "dns_cloudflare_api_token = $api_token" | sudo tee "$conf" >/dev/null
    sudo chmod 600 "$conf"
    run_certbot --dns-cloudflare --dns-cloudflare-propagation-seconds 20 --dns-cloudflare-credentials "$conf"
  elif [ "$ssl_method" = "http" ]; then
    sudo systemctl enable --now nginx  # need to start it now
    setup_certbot && run_certbot --preferred-challenges http
  elif [[ "$ssl_method" == *"/"* ]]; then  # HTTP/S3 URL
    file="certificates.tar.gz"
    download "$ssl_method" "$file" && sudo tar -xvzf "$file" --no-same-owner -C "/etc"
  else
    echo "Unable to set up SSL certificates, make sure they are set up manually if needed"
  fi
fi


##### Setup Services #####
services=()
sudo mkdir -p /etc/systemd/system
if $background_worker; then
  services+=("celery" "celerybeat")
  download_and_install "celery.service"
  download_and_install "celerybeat.service"
  sudo mkdir -p /etc/conf.d
  download_and_install "celery.conf" "/etc/conf.d/celery"
fi
if $server; then
  services+=("gunicorn.service" "gunicorn.socket" "nginx")
  download_and_install "gunicorn.service" && sudo sed -i "s/\$WORKERS/$workers/" /etc/systemd/system/gunicorn.service
  download_and_install "gunicorn.socket"
  sudo mv "$HOME/nginx.conf" "/etc/nginx/conf.d/gunicorn.conf"
  sudo chown root:root "/etc/nginx/conf.d/gunicorn.conf"
  sudo chmod 644 "/etc/nginx/conf.d/gunicorn.conf"
  download_and_install "block-hostname-spoofing.conf" "/etc/nginx/default.d/block-hostname-spoofing.conf"
fi
if $redis; then
  services+=("redis6")
fi


##### Start all of the services #####
sudo systemctl daemon-reload
if $no_config; then
  echo "Please edit config.py before starting the services with the following command:"
  echo "  sudo systemctl enable --now ${services[@]}"
  exit 1
fi

sudo systemctl enable --now "${services[@]}"
