#!/usr/bin/env bash
# Compiles the draco decoder command line utility for reading draco files

# This script generates a tarball that must be copied and unpacked on the
# actual machine running background tasks using:
#   sudo tar -xvzf draco_decoder-*-$(arch)-linux-gnu.tar.gz --no-same-owner -C /usr/local
# The unpacked size is about 1MB.

DRACO_VERSION="1.5.7"

sudo dnf -y install cmake gcc g++

wget -O "draco-$DRACO_VERSION.tar.gz" "https://github.com/google/draco/archive/refs/tags/$DRACO_VERSION.tar.gz" &&
  tar -xzf "draco-$DRACO_VERSION.tar.gz" && cd "draco-$DRACO_VERSION" &&
  mkdir build && cd build && cmake ../ && make -j $(nproc) && mkdir bin && cp draco_decoder-* bin/draco_decoder &&
	tar -czf ../../draco_decoder-"$DRACO_VERSION"-"$(arch)"-linux-gnu.tar.gz --owner=0 --group=0 bin && cd ../..
