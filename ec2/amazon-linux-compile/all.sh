#!/usr/bin/env bash
# Builds necessary 3rd party libraries for Amazon Linux
# This needs to be run on the same type of node, but likely beefier since
# several of these take a lot of RAM and/or hard drive space to compile.

# Uncompressed the binaries and libraries are ~160MB.

# Install common build dependencies
sudo dnf -y group install "Development Tools"
sudo dnf -y install cmake make git gcc g++ pkgconfig curl wget gettext

# Download and run each script
source="https://raw.githubusercontent.com/MoravianUniversity/3DAdapt-AWS-Setup/main/ec2/amazon-linux-compile"
scripts=(
    draco.sh
    openctm.sh
    double-conversion.sh  # needed for building openscad and vtk, not installed on final server
    openscad.sh
    f3d.sh  # includes vtk
)

for script in "${scripts[@]}"; do
    if [ ! -f "$script" ]; then
        wget -O "$script" "$source/$script"
    fi
    if ! bash $script; then
        echo "Failed to run build $script"
        exit 1
    fi
done

echo
echo "All 3rd party libraries have been built:"
ls *-"$(arch)"-linux-gnu.tar.gz
echo "Make sure to copy them off this machine before terminating."
