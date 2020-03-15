#!/usr/bin/env bash
#
# Build the Debian artifacts
#
set -xe
sudo apt-get -qq update
sudo apt-get install devscripts equivs

mkdir  build
cd build
mk-build-deps ../ci/control
sudo apt-get install  ./*all.deb  || :
sudo apt-get --allow-unauthenticated install -f

if [ -n "$BUILD_GTK3" ]; then
    sudo update-alternatives --set wx-config \
        /usr/lib/*-linux-*/wx/config/gtk3-unicode-3.0
fi

#If tagged then build as release
#tag=$(git tag --contains HEAD)

#if [ -n "$tag" ]; then
#  cmake -DCMAKE_BUILD_TYPE=Release ..
#else
#  cmake -DCMAKE_BUILD_TYPE=Debug ..
#fi							  

cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr ..

make -sj2
make package
ls -l 
