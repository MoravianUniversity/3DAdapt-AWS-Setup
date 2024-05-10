#!/usr/bin/env bash
# Script to compile OpenSCAD and dependencies on Amazon Linux 2023 (or any Fedora/REHL-like system)
# This script needs to be run on the same type of machine as it will be
# deployed on but probably a beefier instance type as it takes a lot a
# drive space and RAM to compile.

# At the end, this script generates a tarball that must be copied and
# unpacked on the actual machine running background tasks using:
#   sudo tar -xvzf openscad-$(arch)-linux-gnu.tar.gz --no-same-owner -C /usr/local
# The unpacked size is under 22MB.

# NOTE:
# * the compiled OpenSCAD does NOT require Qt and is completely headless
#   * this causes an issue in that the openscad binary apparently has no idea where it is
#     and thus fails to load resources UNLESS it is run with a full path (e.g. `which openscad`)
# * also installs its own opencsg library and includes the MCAD library but does not use lib3mf

# shellcheck disable=SC2024,SC2164

sudo dnf -y install make cmake gcc g++ patchelf itstool \
    gettext flex bison xorg-x11-server-Xvfb mesa-dri-drivers \
    boost-devel libzip-devel gmp-devel mpfr-devel eigen3-devel tbb-devel libxml2-devel libffi-devel python3.11-devel \
	  glew-devel glib2-devel fontconfig-devel freetype-devel harfbuzz-devel cairo-devel libXmu-devel

# Missing:
#   double-conversion-devel (see double-conversion.sh)
#   opencsg-devel  -  built "inline", see https://github.com/openscad/openscad/pull/4596
#   CGAL-devel     -  built here
#   (qt5-qtbase-devel and qscintilla-qt5-devel, but we don't want a GUI)
#   ragel          -  not available in any repo, needed for something related to harfbuzz (but maybe only if OpenSCAD has to compile, which it doesn't)
# Optional:
#   ImageMagick


##### Clone OpenSCAD #####
# TODO: Wish this wasn't based off of master, but the only other source available is too old for customizer params
rm -rf openscad
git clone https://github.com/openscad/openscad.git && cd openscad && git submodule update --init --recursive || exit 1
OpenSCAD_DIR="$PWD"


##### We have to build some libraries that we don't have on Amazon Linux #####
source ./scripts/setenv-unibuild.sh || exit 1
unset GLEWDIR

# ragel - not sure if this is actually needed (24M binary)
source ./scripts/common-build-dependencies.sh || exit 1
build_ragel 6.10
cd "$OpenSCAD_DIR"

# CGAL (46M in include)
./scripts/uni-build-dependencies.sh cgal || exit 1  # Note: messes up gmp.h detection with dependency checker, but building is okay


##### Build OpenSCAD #####
mkdir -p build && cd build &&
  cmake .. -DHEADLESS=ON -DEXPERIMENTAL=ON -DENABLE_TESTS=OFF -DUSE_BUILTIN_OPENCSG=ON &&
  make -j $(nproc) &&
  sudo make install >installed.txt &&
  mkdir -p "package/lib64" &&
  for file in $(grep "^-- \(Installing\|Up-to-date\): /usr/local/" installed.txt | grep -v "/icons/\|/fonts/\|/examples/\|/locales/\|/editor/\|/templates/" | cut -b 27-); do
    mkdir -p "package/$(dirname "$file")" && cp -P "/usr/local/$file" "package/$file"
  done &&
# shellcheck disable=SC2016
  patchelf --set-rpath '$ORIGIN/../lib64' package/bin/openscad &&
  touch package/share/openscad/locale &&
  cd package && tar -czf ../../../openscad-"$(arch)"-linux-gnu.tar.gz --owner=0 --group=0 -- * && cd ../../..




# Test OpenScad
# cat >input.scad <<EOF
# inner_diameter=41; 
# outer_diameter=inner_diameter+15;
# Thickness=10;
# Handle_length=90; 
# Handle_tip_diameter=15;
# Screw_diam=5;

# difference(){
#     union(){
#         hull(){
#             cylinder(Thickness,d=outer_diameter,center=false);
#             translate([-Handle_length,0,0])cylinder(Thickness,d=Handle_tip_diameter,center=false);
#         }
#         translate([inner_diameter/2,-Screw_diam*2,0])cube([Screw_diam*4,Screw_diam*4,Thickness]);
# }
# union(){
#     cylinder(Thickness,d=inner_diameter,center=false);
#     translate([inner_diameter/3,-Screw_diam/2,0])cube([3*inner_diameter,Screw_diam,Thickness]);
#     translate([inner_diameter/2+Screw_diam*2,-Screw_diam/2,Thickness/2])rotate([90,0,0])cylinder(Screw_diam*6,d=Screw_diam,center=true);
# }
# }
# EOF

# cat >input.json <<EOF
# {
#     "parameterSets": { "vars": { "inner_diameter": 35, "Thickness": 2, "Handle_length": 100 } },
#     "fileFormatVersion": "1"
# }
# EOF
# openscad -o output.stl -p input.json -P vars input.scad
# scp ec2-user@amazonlinux2023:output.stl .