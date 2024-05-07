#!/usr/bin/env bash
# Gathers files and makes redistributable tarballs

# Download and run each script
source="https://raw.githubusercontent.com/MoravianUniversity/3DAdapt-AWS-Setup/main/gather"
scripts=(
    openscad-libs.sh
    google-fonts.sh
    fontconfig-confs.sh
)

for script in "${scripts[@]}"; do
    if [ ! -f "$script" ]; then
        wget -O "$script" "$source/$script"
    fi
    if ! bash $script; then
        echo "Failed to run gather $script"
        exit 1
    fi
done

echo
echo "Resources gathered:"
ls *.tar.?z
