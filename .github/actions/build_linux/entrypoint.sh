#!/bin/sh

set -exu
pwd
ls

apt-get install -y libxcb1-dev libxkbcommon-dev libxkbcommon-x11-dev libgtk-3-dev libgl1-mesa-dev libglu1-mesa-dev libxcb-*-dev git
apt list --installed
cat /etc/*ease

GIT_HASH=32be154325bfba3ad2ba8bf75dad702f3588e8d3
git init qt-src-git
cd qt-src-git
git remote add origin https://invent.kde.org/qt/qt/qt5.git
git fetch --depth=1 origin $GIT_HASH
git checkout $GIT_HASH
git submodule update --init --depth 1
cd ..

make