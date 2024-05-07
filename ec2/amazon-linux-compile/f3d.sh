#!/usr/bin/env bash
# Script to compile VTK and F3D on Amazon Linux 2023 (or any Fedora/REHL-like system)
# This script needs to be run on the same type of machine as it will be
# deployed on but probably a beefier instance type as it takes a lot a
# resources to compile VTK.

# At the end, this script generates two tarballs that must be copied and
# unpacked on the actual machine running background tasks using:
#   sudo tar -xvzf vtk-*-$(arch)-linux-gnu.tar.gz --no-same-owner -C /usr/local
#   sudo tar -xvzf f3d-*-$(arch)-linux-gnu.tar.gz --no-same-owner -C /usr/local
# The unpacked size is just under 100MB.

# Note: the compiled F3D app does NOT require Qt or any xvfb even when headless

# shellcheck disable=SC2024,SC2164

VTK_VERSION="9.3.0"
F3D_VERSION="2.4.0"

sudo dnf -y install gcc g++ make cmake ninja-build python3.11-devel pybind11-devel freeglut-devel mesa-libOSMesa-devel mesa-libGL-devel libX11-devel \
  expat-devel freetype-devel glew-devel libjpeg-turbo-devel jsoncpp-devel lz4-devel xz-devel libpng-devel libtiff-devel zlib-devel eigen3-devel
# those packages combined take >1GB of storage

# Amazon Linux 2023 missing devel packages:
#   * double-conversion-devel: run double-conversion.sh first
#   * pugixml-devel: removed from Amazon Linux... will be provided by VTK building process
#   * fmt-devel: never in Amazon Linux but in Fedora... will be provided by VTK building process

##### Build VTK #####
# Has off-screen rendering but disables support for Qt and a lot of other unneeded things
if [ ! -f "VTK-$VTK_VERSION.tar.gz" ]; then
  wget "https://www.vtk.org/files/release/${VTK_VERSION%.*}/VTK-$VTK_VERSION.tar.gz" || exit 1
fi
rm -rf "VTK-$VTK_VERSION"
tar -xzf "VTK-$VTK_VERSION.tar.gz" && cd "VTK-$VTK_VERSION" &&
  mkdir -p build && cd build &&
  cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DVTK_GROUP_ENABLE_Qt=NO -DVTK_GROUP_ENABLE_Web=NO -DVTK_GROUP_ENABLE_Views=NO -DVTK_OPENGL_HAS_OSMESA=ON -DVTK_USE_X=OFF -DVTK_DEFAULT_RENDER_WINDOW_OFFSCREEN=ON -DVTK_DEFAULT_RENDER_WINDOW_HEADLESS=ON -DVTK_MODULE_ENABLE_VTK_RenderingExternal=YES \
-DVTK_MODULE_ENABLE_VTK_ChartsCore=NO -DVTK_MODULE_ENABLE_VTK_DomainsChemistry=NO -DVTK_MODULE_ENABLE_VTK_DomainsChemistryOpenGL2=NO -DVTK_MODULE_ENABLE_VTK_FiltersAMR=NO -DVTK_MODULE_ENABLE_VTK_FiltersFlowPaths=NO -DVTK_MODULE_ENABLE_VTK_FiltersParallelImaging=NO -DVTK_MODULE_ENABLE_VTK_FiltersPoints=NO -DVTK_MODULE_ENABLE_VTK_FiltersProgrammable=NO -DVTK_MODULE_ENABLE_VTK_FiltersSMP=NO -DVTK_MODULE_ENABLE_VTK_FiltersSelection=NO -DVTK_MODULE_ENABLE_VTK_FiltersTopology=NO -DVTK_MODULE_ENABLE_VTK_GeovisCore=NO -DVTK_MODULE_ENABLE_VTK_IOAMR=NO -DVTK_MODULE_ENABLE_VTK_IOAsynchronous=NO -DVTK_MODULE_ENABLE_VTK_IOCGNSReader=NO -DVTK_MODULE_ENABLE_VTK_IOCONVERGECFD=NO -DVTK_MODULE_ENABLE_VTK_IOCesium3DTiles=NO -DVTK_MODULE_ENABLE_VTK_IOChemistry=NO -DVTK_MODULE_ENABLE_VTK_IOEnSight=NO -DVTK_MODULE_ENABLE_VTK_IOExodus=NO -DVTK_MODULE_ENABLE_VTK_IOExportGL2PS=NO -DVTK_MODULE_ENABLE_VTK_IOExportPDF=NO -DVTK_MODULE_ENABLE_VTK_IOHDF=NO -DVTK_MODULE_ENABLE_VTK_IOIOSS=NO -DVTK_MODULE_ENABLE_VTK_IOInfovis=NO -DVTK_MODULE_ENABLE_VTK_IOLSDyna=NO -DVTK_MODULE_ENABLE_VTK_IOMINC=NO -DVTK_MODULE_ENABLE_VTK_IOMovie=NO -DVTK_MODULE_ENABLE_VTK_IONetCDF=NO -DVTK_MODULE_ENABLE_VTK_IOOggTheora=NO -DVTK_MODULE_ENABLE_VTK_IOParallelXML=NO -DVTK_MODULE_ENABLE_VTK_IOSQL=NO -DVTK_MODULE_ENABLE_VTK_IOSegY=NO -DVTK_MODULE_ENABLE_VTK_IOTecplotTable=NO -DVTK_MODULE_ENABLE_VTK_IOVeraOut=NO -DVTK_MODULE_ENABLE_VTK_IOVideo=NO -DVTK_MODULE_ENABLE_VTK_InfovisCore=NO -DVTK_MODULE_ENABLE_VTK_InfovisLayout=NO -DVTK_MODULE_ENABLE_VTK_RenderingLICOpenGL2=NO -DVTK_MODULE_ENABLE_VTK_RenderingRayTracing=NO -DVTK_MODULE_ENABLE_VTK_ViewsCore=NO -DVTK_MODULE_ENABLE_VTK_WrappingTools=NO \
-DVTK_MODULE_USE_EXTERNAL_VTK_doubleconversion=ON -DVTK_MODULE_USE_EXTERNAL_VTK_eigen=ON -DVTK_MODULE_USE_EXTERNAL_VTK_expat=ON -DVTK_MODULE_USE_EXTERNAL_VTK_freetype=ON -DVTK_MODULE_USE_EXTERNAL_VTK_glew=ON -DVTK_MODULE_USE_EXTERNAL_VTK_jpeg=ON -DVTK_MODULE_USE_EXTERNAL_VTK_jsoncpp=ON -DVTK_MODULE_USE_EXTERNAL_VTK_lz4=ON -DVTK_MODULE_USE_EXTERNAL_VTK_lzma=ON -DVTK_MODULE_USE_EXTERNAL_VTK_png=ON -DVTK_MODULE_USE_EXTERNAL_VTK_tiff=ON -DVTK_MODULE_USE_EXTERNAL_VTK_zlib=ON &&
  cmake --build . &&
  sudo cmake --install . >installed.txt || exit 1

##### Package VTK #####
# This includes libraries, binaries, and share but does not include -devel files:
#     include, lib64/cmake, lib64/vtk-*/hierarchy
for file in $(grep "^-- \(Installing\|Up-to-date\): /usr/local/" installed.txt | grep -v "/include/\|/lib64/cmake/\|/hierarchy/" | cut -b 27-); do
  mkdir -p "package/$(dirname "$file")" && cp -P "/usr/local/$file" "package/$file"
done && 
  cd package &&
  tar -czf ../../../vtk-"$VTK_VERSION"-"$(arch)"-linux-gnu.tar.gz --owner=0 --group=0 -- * || exit 1

# Make the devel package:
#for file in $(grep "^-- \(Installing\|Up-to-date\): /usr/local/" installed.txt | grep "/include/\|/lib64/cmake/\|/hierarchy/" | cut -b 27-); do
#    mkdir -p "package-devel/$(dirname "$file")" && cp -P "/usr/local/$file" "package-devel/$file"
#done
#cd package-devel
#tar -czf ../../../vtk-"$VTK_VERSION"-devel-aarch64-linux-gnu.tar.gz --owner=0 --group=0 -- *

cd ../../..


##### Build F3D #####
if [ ! -f "f3d-$F3D_VERSION.tar.gz" ]; then
  wget -O "f3d-$F3D_VERSION.tar.gz" "https://github.com/f3d-app/f3d/archive/refs/tags/v$F3D_VERSION.tar.gz" || exit 1
fi
rm -rf "f3d-$F3D_VERSION"
tar -xzf "f3d-$F3D_VERSION.tar.gz" && cd f3d-$F3D_VERSION && mkdir build && cd build &&
  cmake .. -GNinja -DF3D_MODULE_EXTERNAL_RENDERING=ON -DF3D_BINDINGS_PYTHON=ON -DF3D_PLUGIN_BUILD_EXODUS=OFF &&
  cmake --build . &&
  sudo cmake --install . >installed.txt &&
  sudo cmake --install . --component sdk >installed-sdk.txt || exit 1

##### Package F3D #####
# This includes everything from --install and --install --component sdk
for file in $(cat installed.txt installed-sdk.txt | grep "^-- \(Installing\|Up-to-date\): /usr/local/" | cut -b 27-); do
  mkdir -p "package/$(dirname "$file")" && cp -P "/usr/local/$file" "package/$file"
done && 
  cd package &&
  tar -czf ../../../f3d-"$F3D_VERSION"-"$(arch)"-linux-gnu.tar.gz --owner=0 --group=0 -- * &&
  cd ../../..
