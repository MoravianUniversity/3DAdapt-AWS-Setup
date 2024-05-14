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
  expat-devel freetype-devel libjpeg-turbo-devel jsoncpp-devel lz4-devel xz-devel libpng-devel libtiff-devel zlib-devel eigen3-devel
# those packages combined take >1GB of storage

# Amazon Linux 2023 missing devel packages:
#   * double-conversion-devel: run double-conversion.sh first
#   * pugixml-devel: removed from Amazon Linux... will be provided by VTK building process
#   * fmt-devel: never in Amazon Linux but in Fedora... will be provided by VTK building process

##### Build VTK #####
# Has headless rendering but disables support for Qt and a lot of other unneeded things
if [ ! -f "VTK-$VTK_VERSION.tar.gz" ]; then
  wget "https://www.vtk.org/files/release/${VTK_VERSION%.*}/VTK-$VTK_VERSION.tar.gz" || exit 1
fi
rm -rf "VTK-$VTK_VERSION"
tar -xzf "VTK-$VTK_VERSION.tar.gz" && cd "VTK-$VTK_VERSION" &&
  mkdir -p build && cd build &&
  cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DVTK_OPENGL_HAS_OSMESA=ON -DVTK_USE_X=OFF -DVTK_MODULE_ENABLE_VTK_RenderingExternal=YES -DVTK_MODULE_ENABLE_VTK_RenderingImage=YES -DVTK_DEFAULT_RENDER_WINDOW_HEADLESS=ON \
           -DVTK_GROUP_ENABLE_Qt=NO -DVTK_MODULE_ENABLE_VTK_RenderingQt=NO -DVTK_MODULE_ENABLE_VTK_GUISupportQt=NO -DVTK_MODULE_ENABLE_VTK_GUISupportQtQuick=NO -DVTK_MODULE_ENABLE_VTK_GUISupportQtSQL=NO -DVTK_MODULE_ENABLE_VTK_ViewsQt=NO \
           -DVTK_GROUP_ENABLE_Web=NO -DVTK_MODULE_ENABLE_VTK_WebCore=NO -DVTK_MODULE_ENABLE_VTK_WebGLExporter=NO -DVTK_GROUP_ENABLE_Views=NO -DVTK_MODULE_ENABLE_VTK_ViewsCore=NO -DVTK_MODULE_ENABLE_VTK_ViewsInfovis=NO \
           -DVTK_MODULE_ENABLE_VTK_ChartsCore=NO -DVTK_MODULE_ENABLE_VTK_DomainsChemistry=NO -DVTK_MODULE_ENABLE_VTK_DomainsChemistryOpenGL2=NO -DVTK_MODULE_ENABLE_VTK_FiltersAMR=NO -DVTK_MODULE_ENABLE_VTK_FiltersFlowPaths=NO -DVTK_MODULE_ENABLE_VTK_FiltersParallelImaging=NO -DVTK_MODULE_ENABLE_VTK_FiltersPoints=NO -DVTK_MODULE_ENABLE_VTK_FiltersProgrammable=NO -DVTK_MODULE_ENABLE_VTK_FiltersSMP=NO -DVTK_MODULE_ENABLE_VTK_FiltersSelection=NO -DVTK_MODULE_ENABLE_VTK_FiltersTopology=NO -DVTK_MODULE_ENABLE_VTK_GeovisCore=NO -DVTK_MODULE_ENABLE_VTK_IOAMR=NO -DVTK_MODULE_ENABLE_VTK_IOAsynchronous=NO -DVTK_MODULE_ENABLE_VTK_IOCGNSReader=NO -DVTK_MODULE_ENABLE_VTK_IOCONVERGECFD=NO -DVTK_MODULE_ENABLE_VTK_IOCesium3DTiles=NO -DVTK_MODULE_ENABLE_VTK_IOChemistry=NO -DVTK_MODULE_ENABLE_VTK_IOEnSight=NO -DVTK_MODULE_ENABLE_VTK_IOExodus=NO -DVTK_MODULE_ENABLE_VTK_IOExportGL2PS=NO -DVTK_MODULE_ENABLE_VTK_IOExportPDF=NO -DVTK_MODULE_ENABLE_VTK_IOHDF=NO -DVTK_MODULE_ENABLE_VTK_IOIOSS=NO -DVTK_MODULE_ENABLE_VTK_IOInfovis=NO -DVTK_MODULE_ENABLE_VTK_IOLSDyna=NO -DVTK_MODULE_ENABLE_VTK_IOMINC=NO -DVTK_MODULE_ENABLE_VTK_IOMovie=NO -DVTK_MODULE_ENABLE_VTK_IONetCDF=NO -DVTK_MODULE_ENABLE_VTK_IOOggTheora=NO -DVTK_MODULE_ENABLE_VTK_IOParallelXML=NO -DVTK_MODULE_ENABLE_VTK_IOSQL=NO -DVTK_MODULE_ENABLE_VTK_IOSegY=NO -DVTK_MODULE_ENABLE_VTK_IOTecplotTable=NO -DVTK_MODULE_ENABLE_VTK_IOVeraOut=NO -DVTK_MODULE_ENABLE_VTK_IOVideo=NO -DVTK_MODULE_ENABLE_VTK_InfovisCore=NO -DVTK_MODULE_ENABLE_VTK_InfovisLayout=NO -DVTK_MODULE_ENABLE_VTK_RenderingLICOpenGL2=NO -DVTK_MODULE_ENABLE_VTK_RenderingRayTracing=NO -DVTK_MODULE_ENABLE_VTK_ViewsCore=NO -DVTK_MODULE_ENABLE_VTK_WrappingTools=NO \
           -DVTK_MODULE_USE_EXTERNAL_VTK_glew=OFF -DVTK_MODULE_USE_EXTERNAL_VTK_doubleconversion=ON -DVTK_MODULE_USE_EXTERNAL_VTK_eigen=ON -DVTK_MODULE_USE_EXTERNAL_VTK_expat=ON -DVTK_MODULE_USE_EXTERNAL_VTK_freetype=ON -DVTK_MODULE_USE_EXTERNAL_VTK_jpeg=ON -DVTK_MODULE_USE_EXTERNAL_VTK_jsoncpp=ON -DVTK_MODULE_USE_EXTERNAL_VTK_lz4=ON -DVTK_MODULE_USE_EXTERNAL_VTK_lzma=ON -DVTK_MODULE_USE_EXTERNAL_VTK_png=ON -DVTK_MODULE_USE_EXTERNAL_VTK_tiff=ON -DVTK_MODULE_USE_EXTERNAL_VTK_zlib=ON &&
  cmake --build . &&
  sudo cmake --install . >installed.txt || exit 1

##### Package VTK #####
# This includes libraries, binaries, and share but does not include -devel files:
#     include, lib64/cmake, lib64/vtk-*/hierarchy
for file in $(grep "^-- \(Installing\|Up-to-date\): /usr/local/" installed.txt | grep -v "/include/\|/lib64/cmake/\|/hierarchy/" | cut -b 27-); do
  mkdir -p "package/$(dirname "$file")" && cp -P "/usr/local/$file" "package/$file"
done && 
  cd package &&
  tar -czf ../../../vtk-"$VTK_VERSION"-"$(arch)"-linux-gnu.tar.gz --owner=0 --group=0 -- * && cd .. || exit 1

# Make the devel package:
#for file in $(grep "^-- \(Installing\|Up-to-date\): /usr/local/" installed.txt | grep "/include/\|/lib64/cmake/\|/hierarchy/" | cut -b 27-); do
#  mkdir -p "package-devel/$(dirname "$file")" && cp -P "/usr/local/$file" "package-devel/$file"
#done &&
#  cd package-devel &&
#  tar -czf ../../../vtk-"$VTK_VERSION"-devel-"$(arch)"-linux-gnu.tar.gz --owner=0 --group=0 -- * && cd .. || exit 1

cd ../..


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


# Test F3D
# =================

# cat >config.json <<EOF
# {
#   ".*": {
#     "bg-color":"0.05,0.05,0.05","color":"0.502,0.922,1.0",
#     "filename":false,"axis":false,"grid":true,"roughness":0.5,
#     "camera-elevation-angle":25,"camera-azimuth-angle":-45,
#     "tone-mapping":true,"fxaa":true
#   },
#   ".*stl": {"up":"+Z"}
# }
# EOF

# cat >tetrahedron.stl <<EOF
# solid
#   facet normal -0.816496610641 0.47140455246 -0.33333337307
#     outer loop
#       vertex 0.0 0.0 10.0
#       vertex -1.73191217362e-15 -9.42809009552 -3.33333301544
#       vertex 8.16496562958 4.7140455246 -3.33333349228
#     endloop
#   endfacet
#   facet normal 0.0 -0.942809045315 -0.33333337307
#     outer loop
#       vertex 0.0 0.0 10.0
#       vertex 8.16496562958 4.7140455246 -3.33333349228
#       vertex -8.16496562958 4.7140455246 -3.33333349228
#     endloop
#   endfacet
#   facet normal 0.816496610641 0.47140455246 -0.33333337307
#     outer loop
#       vertex 0.0 0.0 10.0
#       vertex -8.16496562958 4.7140455246 -3.33333349228
#       vertex -1.73191217362e-15 -9.42809009552 -3.33333301544
#     endloop
#   endfacet
#   facet normal 0.0 3.37174768106e-08 1.0
#     outer loop
#       vertex -1.73191217362e-15 -9.42809009552 -3.33333301544
#       vertex -8.16496562958 4.7140455246 -3.33333349228
#       vertex 8.16496562958 4.7140455246 -3.33333349228
#     endloop
#   endfacet
# endsolid
# EOF

# f3d tetrahedron.stl --config ./config.json --output output.png --resolution 1800,1350

# scp ec2-user@amazonlinux2023:output.png .
