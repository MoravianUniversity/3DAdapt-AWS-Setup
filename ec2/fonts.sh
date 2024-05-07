#!/usr/bin/env bash
# Additional fonts for use with OpenSCAD
# OpenSCAD is only run on the background workers
# This script is intended to be run on an Amazon Linux 2023 instance
# Supports setting the source HTTP/S3 URL for downloading packages and other scripts (and separate URLs for Google Fonts)

# This includes:
#   * all CadHub fonts (https://learn.cadhub.xyz/docs/general-cadhub/openscad-fonts/)
#   * all Makerbot/Thingiverse OpenSCAD Customizer fonts^
#   * all MakeWithTech fonts^ (https://www.makewithtech.com/post/more-fonts-added-to-models)
#   * all OnShape fonts^
# Plus several additional fonts
#
#^ Only when providing the OFL-licensed Google Fonts repo (~2G), but code is provided to do so below; missing fonts are:
#   * Makerbot: had full Google Font repo from several years ago
#   * MakeWithTech: OFL Google Fonts: Hurricane, IBM Plex Sans, Lato, Montserrat, Open Sans
#   * OnShape: OFL Google Fonts: Allerta, Allerta Stencil, Balthazar, Baumans, Bebas Neue, Comic Neue, Courier Prime, Didact Gothic, Inconsolata, Inter, MPLUSRounded1c, Michroma, Open Sans, Orbitron, Oswald, PTSans, Poppins, Rajdhani, Ropa Sans, Sofia Sans, Tinos


# if not already set by the calling script, set the source URL for downloading packages and other scripts
[ -z "$source" ] && source="https://raw.githubusercontent.com/MoravianUniversity/3DAdapt-AWS-Setup/main/packages"
[ -z "$google_font_source" ] && google_font_source="$source"


# Helper function to download files from either HTTP or S3
function download() {
    uri="$1"
    output="$2"
    [ -z "$output" ] && output="$(basename "$uri")"
    if [[ "$uri" =~ ^s3 ]]; then
        aws s3 cp "$uri" "$output" --no-progress || exit 1
    else
        wget -nv -O "$output" "$uri" || exit 1
    fi
}


# Tools for installing fonts
sudo dnf install fontconfig mkfontscale xorg-x11-font-utils xorg-x11-server-utils
sudo mkdir -p /usr/local/share/fonts

##### Easy to install and useful fonts (57M) #####
sudo dnf install bitstream-vera-fonts-all dejavu*fonts-all fontawesome-fonts google-droid-fonts-all liberation-fonts oldstandard-sfd-fonts urw-base35-fonts
# sudo dnf install abattis-cantarell-fonts adobe-source-*-fonts overpass*-fonts \  # all in Google Fonts OFL
#   google-noto-sans-vf-fonts google-noto-sans-mono-vf-fonts google-noto-serif-vf-fonts google-noto-*-display*-vf-fonts google-noto-*-symbols-vf-fonts google-noto-*-symbols2-fonts google-noto-emoji-fonts
# sudo dnf install google-roboto-slab-fonts  # all in Google Fonts Apache Licensed
# others: lots of foreign-language fonts, but they are large (totalling ~2.5G) [might as well do the full google-fonts, but this one does include a few other foreign language fonts not in google-fonts]

##### Microsoft core fonts #####
ARCH="$(rpm --eval '%{_arch}')"  # aarch64 or x86_64
sudo rpm -i https://dl.fedoraproject.org/pub/epel/9/Everything/$ARCH/Packages/c/cabextract-1.9.1-3.el9.$ARCH.rpm
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

##### Microsoft look-alike fonts #####
# TODO: should I move the included local.conf.arkpandora to /etc/fonts/conf.d/99-arkpandora.conf?
ARKPANDORA_VERSION="2.04"
wget -O fonts-arkpandora.tar.gz "http://ftp.debian.org/debian/pool/main/f/fonts-arkpandora/fonts-arkpandora_$ARKPANDORA_VERSION.orig.tar.gz" && \
  tar -xzf fonts-arkpandora.tar.gz && \
  sudo mv "ttf-arkpandora-$ARKPANDORA_VERSION" /usr/local/share/fonts/arkpandora && \
  rm -rf fonts-arkpandora.tar.gz

##### Google Go Font #####
sudo rpm -i http://fedora.mirror.constant.com/fedora/linux/releases/38/Everything/aarch64/os/Packages/g/google-go-smallcaps-fonts-0.5.0-1.fc38.noarch.rpm
sudo rpm -i http://fedora.mirror.constant.com/fedora/linux/releases/38/Everything/aarch64/os/Packages/g/google-go-mono-fonts-0.5.0-1.fc38.noarch.rpm
sudo rpm -i http://fedora.mirror.constant.com/fedora/linux/releases/38/Everything/aarch64/os/Packages/g/google-go-fonts-0.5.0-1.fc38.noarch.rpm

##### OpenSans Condensed ##### (confused about its Google Font status)
wget -O open-sans-condensed.zip https://www.fontsquirrel.com/fonts/download/open-sans-condensed &&
  mkdir open-sans-condensed && cd open-sans-condensed && unzip ../open-sans-condensed.zip && cd .. \
  sudo mv open-sans-condensed /usr/local/share/fonts/open-sans-condensed && \
  rm -rf open-sans-condensed.zip

##### Google Fonts #####
# Massive free library of fonts (https://github.com/google/fonts, nice UI at https://fonts.google.com/)
# However, it is 2.22GB decompressed... it can be cleaned up a bit though, see gather/google-fonts.sh for re-packaging it
for lib in apache ufl ofl; do  # 18M, 4M, and 1.9G** decompressed
  download "$google_font_source/google-fonts-$lib.tar.xz" &&
    tar -xJf "google-fonts-$lib.tar.xz" && sudo mv "$lib"/* /usr/local/share/fonts && rm -rf "$lib"
done

# Find all fontconfig conf files for all of the dnf-installable fonts
# Helps with fontconfig matching and alternate names, see gather/fontconfig-confs.sh for generating the tarball and more information
download "$source/fontconfig-confs.tar.gz" && sudo tar -xzf fontconfig-confs.tar.gz --skip-old-files --no-same-owner -C /


##### Make sure the cache is updated #####
sudo fc-cache -f -v


# TODO: create a list of fonts (by common name, not PO52 which is better known as Palatino or Palatino Linotype)
# A start would be `grep -A1 "binding=\"same\"" /etc/fonts/conf.d/*`
# But then the family (second line) needs to be be checked with `fc-match` to see if it resolves to a font that is just the default font
