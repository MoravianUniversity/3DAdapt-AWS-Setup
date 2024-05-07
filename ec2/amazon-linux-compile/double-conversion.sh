#!/usr/bin/env bash
# Script to compile double-conversion from source on Amazon Linux 2023 (or any Fedora/REHL-like system)
# This script needs to be run on the same type of machine as it will be deployed on.

# This script is required before running openscad.sh or vtk.sh since they both depend on double-conversion.

# At the end, this script a tarball that must be copied and unpacked on the actual machine running background tasks using:
#   sudo tar -xvzf double-conversion-*-$(arch)-linux-gnu.tar.gz --no-same-owner -C /usr/local
# The unpacked size is 400KB. It includes the devel material in the tarball.

DC_VERSION="3.3.0"

sudo dnf -y install cmake gcc g++

wget -O "double-conversion-$DC_VERSION.tar.gz" https://github.com/google/double-conversion/archive/refs/tags/v$DC_VERSION.tar.gz &&
  tar -xzf "double-conversion-$DC_VERSION.tar.gz" && cd "double-conversion-$DC_VERSION"
  
# Create static library
cmake . && make -j $(nproc) && sudo make install >installed-static.txt

# Create shared library
# cmake . -DBUILD_SHARED_LIBS=ON && make -j $(nproc) && sudo make install >installed-shared.txt &&
#  for file in $(grep "^-- \(Installing\|Up-to-date\): /usr/local/" installed-shared.txt | cut -b 27-); do
#    mkdir -p "package/$(dirname "$file")" && cp -P "/usr/local/$file" "package/$file"
#  done && cd package &&
#  tar -czf ../../double-conversion-"$DC_VERSION"-"$(arch)"-linux-gnu.tar.gz --owner=0 --group=0 -- * &&
#  cd ../..
