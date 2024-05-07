#!/usr/bin/env bash
# Install common OpenSCAD libraries (<15M)
# If already packaged:
#   sudo tar -xzf openscad-libraries.tar.gz --no-same-owner -C /usr/local/share/openscad/libraries/

# Includes:
#   use <MCAD/*.scad> - installed with OpenSCAD itself
#   use <write/Write.scad>             [from https://www.thingiverse.com/thing:16193] (kinda useless since text() exists now...)
#   use <pins/pins.scad>               [from https://www.thingiverse.com/thing:10541]
#   use <utils/build_plate.scad>       [from https://www.thingiverse.com/thing:44094]
#   use <utils/hsvtorgb.scad>          [from https://www.thingiverse.com/thing:279951]
#   use <utils/3dvector.scad>          [from https://www.thingiverse.com/thing:279886]
#   use <attach.scad>                  [from https://www.thingiverse.com/thing:30136]
#   use <local.scad>                   [from https://github.com/jreinhardt/local-scad]
#   use <obiscad/*.scad>               [from https://github.com/Obijuan/obiscad]
#   use <BOSL/*.scad>                  [from https://github.com/revarbat/BOSL, v1.0.3]
#   use <BOSL2/*.scad>                 [from https://github.com/BelfrySCAD/BOSL2, beta from August 2023]
#   use <dotSCAD/*.scad>               [from https://github.com/JustinSDK/dotSCAD, v3.3]
#   use <Nop/*.scad>                   [from https://github.com/nophead/NopSCADlib, cloned August 2023]
#     also available as <NopSCADlib/*.scad>
#   include <UB/*.scad>                [from https://github.com/UBaer21/UB.scad, cloned August 2023]
#     also available as <ub.scad>
#   use <functional/*.scad>            [from https://github.com/thehans/FunctionalOpenSCAD]
#   include <constructive-compiled.scad> [from https://github.com/solidboredom/constructive, cloned August 2023]
#   include <BOLTS/BOLTS.scad>         [from https://github.com/boltsparts/BOLTS_archive, v0.4.1]
#     also available as <BOLTS.scad>
#   include <Round-Anything/*.scad>    [from https://github.com/Irev-Dev/Round-Anything, v1.0.4]
#     also available as <Round-Anything-1.0.4/*.scad> and <polyround.scad>
#   include <hingebox_code.scad>       [from https://github.com/sbambach/MarksEnclosureHelper]
#   include <funcutils/*.scad>         [from https://github.com/thehans/funcutils]
#   include <threads.scad>             [from https://github.com/rcolyer/threads-scad]
#   include <smooth_prim.scad>         [from https://github.com/rcolyer/smooth-prim]
#   include <plot_function.scad>       [from https://github.com/rcolyer/plot-function]
#   include <closepoints.scad>         [from https://github.com/rcolyer/closepoints]
#   include <tray.scad>                [from https://github.com/sofian/openscad-tray]
#   include <YAPP_Box/*.scad>          [from https://github.com/mrWheel/YAPP_Box, v1.9]
#   include <stemfie*.scad>            [from https://github.com/Cantareus/Stemfie_OpenSCAD]
#   use <catchnhole.scad>              [from https://github.com/mmalecki/catchnhole, cloned August 2023]
#   use <pathbuilder.scad>             [from https://github.com/dinther/pathbuilder, cloned August 2023]
#   use <meshbuilder.scad>             [from https://github.com/dinther/pathbuilder, cloned August 2023]
#   include <A2D.scad>                 [from https://github.com/ridercz/A2D]

mkdir -p openscad-libraries && cd openscad-libraries


##### From original Makerbot/Thingiverse OpenSCAD Customizer #####
# see https://customizer.makerbot.com/docs
# Note: thingiverse gives 403 Forbidden when using wget, but not with curl
mkdir -p write
curl -sSL -o write/Write.scad https://www.thingiverse.com/download:559787
curl -sSL -o write/Letters.dxf https://www.thingiverse.com/download:53290
curl -sSL -o write/BlackRose.dxf https://www.thingiverse.com/download:54261
curl -sSL -o write/orbitron.dxf https://www.thingiverse.com/download:54052
curl -sSL -o write/knewave.dxf https://www.thingiverse.com/download:54123
curl -sSL -o write/braille.dxf https://www.thingiverse.com/download:54051

mkdir -p pins
curl -sSL -o pins/pins.scad https://www.thingiverse.com/download:33538

mkdir -p utils
curl -sSL -o utils/build_plate.scad https://www.thingiverse.com/download:121626
curl -sSL -o utils/hsvtorgb.scad	https://www.thingiverse.com/download:550920
curl -sSL -o utils/3dvector.scad https://www.thingiverse.com/download:508835

##### Small, Common, Libraries #####
curl -sSL -o local.scad https://github.com/jreinhardt/local-scad/blob/master/local.scad
curl -sSL -o attach.scad https://www.thingiverse.com/download:88301
git clone https://github.com/Obijuan/obiscad.git && mv obiscad obiscad-root && mv obiscad-root/obiscad . && rm -rf obiscad-root

##### From OpenSCAD list of Libraries #####
# see https://openscad.org/libraries.html

# BOSL
BOSL_VERSION=1.0.3
curl -sSL -o "BOSL.tar.gz" "https://github.com/revarbat/BOSL/archive/refs/tags/v$BOSL_VERSION.tar.gz" &&
  tar -xzf "BOSL.tar.gz" && mv "BOSL-$BOSL_VERSION" BOSL && find BOSL -type f ! -name '*.scad' -delete && rm -rf BOSL/*/
rm -rf "BOSL.tar.gz"

# BOSL2
git clone https://github.com/BelfrySCAD/BOSL2.git &&
  find BOSL2 -type f ! -name '*.scad' ! -name '*.py' -delete && mv BOSL2/scripts/img2scad.py BOSL2/img2scad.py && rm -rf BOSL2/*/ BOSL2/.git

# dotSCAD
dotSCAD_VERSION=3.3
curl -sSL -o "dotSCAD.tar.gz" "https://github.com/JustinSDK/dotSCAD/archive/refs/tags/v$dotSCAD_VERSION.tar.gz" &&
  tar -xzf "dotSCAD.tar.gz" && mv "dotSCAD-$dotSCAD_VERSION/src" dotSCAD && rm -rf "dotSCAD-$dotSCAD_VERSION"
rm -rf "dotSCAD.tar.gz"

# NopSCADlib
git clone https://github.com/nophead/NopSCADlib.git &&
  mkdir -p Nop && mv NopSCADlib/core.scad NopSCADlib/global_defs.scad NopSCADlib/lib.scad NopSCADlib/printed NopSCADlib/utils NopSCADlib/vitamins Nop/
  rm -rf NopSCADlib && ln -s Nop NopSCADlib

# UB
mkdir -p UB &&
  curl -sSL -o UB/ub.scad https://github.com/UBaer21/UB.scad/blob/main/libraries/ub.scad && ln -s UB/ub.scad ub.scad
  curl -sSL -o UB/products.scad https://github.com/UBaer21/UB.scad/blob/main/libraries/products.scad

# Functional
git clone https://github.com/thehans/FunctionalOpenSCAD.git &&
  mkdir -p functional && mv FunctionalOpenSCAD/*.scad functional/ && rm -rf FunctionalOpenSCAD

# Constructive
curl -sSL -o constructive-compiled.scad https://github.com/solidboredom/constructive/raw/main/constructive-compiled.scad

# BOLTS
BOLTS_VERSION=0.4.1
curl -sSL -o BOLTS.tar.gz "https://github.com/boltsparts/BOLTS_archive/releases/download/v$BOLTS_VERSION/boltsos_$BOLTS_VERSION.tar.gz" &&
  mkdir -p BOLTS && cd BOLTS && tar -xzf ../BOLTS.tar.gz && rm -rf LICENSE && cd .. && echo "include <BOLTS/BOLTS.scad>" >BOLTS.scad
rm -rf rm BOLTS.tar.gz

# Round Anything
RA_VERSION=1.0.4
curl -sSL -o round-anything.tar.gz "https://github.com/Irev-Dev/Round-Anything/archive/refs/tags/$RA_VERSION.tar.gz" &&
  tar -xzf round-anything.tar.gz && cd "Round-Anything-$RA_VERSION" && rm -rf -- images *.md *.stl LICENSE *Example* && cd .. &&
  ln -s "Round-Anything-$RA_VERSION" Round-Anything && echo "include <Round-Anything-$RA_VERSION/polyround.scad>" >polyround.scad &&
rm -rf round-anything.tar.gz

# Mark's Enclosure Helper
curl -sSL -o hingebox_code.scad https://github.com/sbambach/MarksEnclosureHelper/raw/master/hingebox_code.scad

# funcutils
git clone https://github.com/thehans/funcutils.git &&
  find funcutils -type f ! -name '*.scad' -delete && rm -rf funcutils/*/ funcutils/.git

# rcolyer libraries (threads, smooth_prim, plot_function, and closepoints)
curl -sSL -o threads.scad https://github.com/rcolyer/threads-scad/raw/master/threads.scad
curl -sSL -o smooth_prim.scad https://github.com/rcolyer/smooth-prim/raw/master/smooth_prim.scad
curl -sSL -o plot_function.scad https://github.com/rcolyer/plot-function/raw/master/plot_function.scad
curl -sSL -o closepoints.scad https://github.com/rcolyer/closepoints/raw/master/closepoints.scad

# Tray Library
curl -sSL -o tray.scad https://github.com/sofian/openscad-tray/raw/main/tray.scad

# YAPP Box
YAPP_Box_VERSION=1.9
curl -sSL -o YAPP_Box.tar.gz "https://github.com/mrWheel/YAPP_Box/archive/refs/tags/v$YAPP_Box_VERSION.tar.gz" &&
  tar -xzf YAPP_Box.tar.gz && mv "YAPP_Box-$YAPP_Box_VERSION/library" YAPP_Box && rm -rf "YAPP_Box-$YAPP_Box_VERSION"
rm -rf YAPP_Box.tar.gz

# STEMFIE
curl -sSL -o stemfie.scad https://github.com/Cantareus/Stemfie_OpenSCAD/raw/main/stemfie.scad
curl -sSL -o stemfie_electrics.scad https://github.com/Cantareus/Stemfie_OpenSCAD/raw/main/stemfie_electrics.scad

# Catch'n'Hole
curl -sSL -o catchnhole.scad https://raw.githubusercontent.com/mmalecki/catchnhole/latest/catchnhole.scad
curl -sSL -o bolts.json https://raw.githubusercontent.com/mmalecki/catchnhole/latest/bolts.json
curl -sSL -o nuts.json https://raw.githubusercontent.com/mmalecki/catchnhole/latest/nuts.json

# Pathbuilder
curl -sSL -o pathbuilder.scad https://github.com/dinther/pathbuilder/raw/main/pathbuilder.scad
curl -sSL -o meshbuilder.scad https://github.com/dinther/pathbuilder/raw/main/meshbuilder.scad

# Altair's 2D Library for OpenSCAD
curl -sSL -o A2D.scad https://github.com/ridercz/A2D/raw/master/A2D.scad


##### Create Package / Copy to System #####
tar -czf ../openscad-libraries.tar.gz --owner=0 --group=0 -- * && cd ..
rm -rf openscad-libraries
