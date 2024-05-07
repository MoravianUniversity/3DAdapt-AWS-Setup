#!/usr/bin/env bash
# Download and re-package Google Fonts for use with OpenSCAD
# Google Fonts is a massive free library of fonts (https://github.com/google/fonts, nice UI at https://fonts.google.com/)
# However, it is 2.22GB decompressed... it can be cleaned up a bit though

# To install from these tarballs:
#    tar -xJf "google-fonts-$lib.tar.xz" && sudo mv "$lib"/* /usr/local/share/fonts && rm -rf "$lib"

wget -O fonts-main.zip https://github.com/google/fonts/archive/main.zip &&
  unzip fonts-main.zip '*.ttf' && cd fonts-main && rm -rf axisregistry lang && find . -type f -executable -exec chmod -x {} \;
# note: axisregistry contains the OpenSansCondensed(-Italic) font and lang contains the Nunito-Regular font not found anywhere else in the repo
XZ_OPT=-9 tar -cJf google-fonts-apache.tar.xz --owner=0 --group=0 apache  # 18M decompressed
XZ_OPT=-9 tar -cJf google-fonts-ufl.tar.xz --owner=0 --group=0 ufl  # 4M decompressed
XZ_OPT="-9 -e -T 0" tar -cJf google-fonts-ofl.tar.xz --owner=0 --group=0 ofl  # 1.9G decompressed, does include foreign language fonts though
rm -rf apache ufl ofl
mv google-fonts-*.tar.xz .. && cd .. && rm -rf fonts-main fonts-main.zip
