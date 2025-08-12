#!/bin/bash

### Build Your External Libraries Here ###
git clone https://code.videolan.org/videolan/dav1d.git
cd dav1d
meson build --prefix=/usr/local --buildtype release
ninja -C build
sudo ninja -C build install
