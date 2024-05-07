#!/usr/bin/env bash
# Compiles the OpenCTM library for reading CTM files

# This script generates a tarball that must be copied and unpacked on the
# actual machine running background tasks using:
#   sudo tar -xvzf openctm-*-$(arch)-linux-gnu.tar.gz --no-same-owner -C /usr/local
# The unpacked size is under 1MB.

CTM_VERSION="1.0.3"

sudo dnf -y install make gcc

wget -O openctm.tar.bz2 "https://sourceforge.net/projects/openctm/files/OpenCTM-$CTM_VERSION/OpenCTM-$CTM_VERSION-src.tar.bz2/download" &&
  tar -xjf "openctm.tar.bz2" && cd "OpenCTM-$CTM_VERSION" &&
  make -f Makefile.linux openctm -j $(nproc) &&
  mkdir -p lib64 && cp lib/libopenctm.so lib64/ &&
  mkdir -p include && cp lib/openctm*.h include/ &&
  tar -czf ../openctm-"$CTM_VERSION"-"$(arch)"-linux-gnu.tar.gz --owner=0 --group=0 lib64 include && cd ..
