#!/usr/bin/env bash
# Find all fontconfig conf files for all of the dnf-installable fonts
# Helps with fontconfig matching and alternate names
# This downloads a lot of data
# Running on a regular Fedora machine will get extra conf files that are useful (as opposed to amazon-linux which will be more limited)

# To install from this tarball:
#     sudo tar -xzf fontconfig-confs.tar.gz --skip-old-files --no-same-owner -C /

if ! which dnf &>/dev/null; then
  echo "This script is for dnf-based systems only"
  exit 1
fi

sudo dnf install -y rpm cpio

mkdir -p conf-temp && cd conf-temp &&
  sudo dnf download abattis-cantarell-fonts adobe-source-*-fonts overpass*-fonts google*-fonts --resolve &&
  for rpm in *.rpm; do rpm2cpio "$rpm" | cpio --quiet -uvdi -- *.conf; done &&
  tar -czf ../fontconfig-confs.tar.gz --owner=0 --group=0 etc usr && cd .. && rm -rf conf-temp
