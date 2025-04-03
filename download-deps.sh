#!/bin/bash
#
# Build dependencies script - a52sxq
# Coded by btngana24680 @2025
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

TC_URL=https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/4c6fbc28d3b078a5308894fc175f962bb26a5718/clang-r383902b1.tar.gz
AVB_URL=https://android.googlesource.com/platform/external/avb/+archive/refs/heads/main.tar.gz
MAGISK_URL=$(curl -s https://api.github.com/repos/topjohnwu/Magisk/releases/latest | jq -r '.assets[] | select(.name | test("Magisk.*.apk$")) | .browser_download_url')

TC_DIR="$1"

# Download avbtool:
echo "----------------------------------------------"
if [ ! -f avbtool ]; then
	echo "Downloading avbtool..."
	curl -L $AVB_URL -o avb.tar.gz
	mkdir avbtooldir
	tar -xzf avb.tar.gz -C avbtooldir
	rm -rf avb.tar.gz
	mv avbtooldir/avbtool.py avbtool
	rm -rf avbtooldir
	chmod +x avbtool
else
	echo "avbtool found, Skipping..."
fi

# Download magiskboot
echo "----------------------------------------------"
if [ ! -f magiskboot_x86 ]; then
	echo "Downloading magisk boot..."
	curl -L "$MAGISK_URL" -o Magisk.zip
	mkdir magisk
	unzip Magisk.zip -d magisk
	rm -rf Magisk.zip
	cp magisk/lib/x86/libmagiskboot.so magiskboot_x86
	rm -rf magisk
	chmod +x magiskboot_x86
else
	echo "Magisk boot found, Skipping..."
fi

# Download toolchain
echo "----------------------------------------------"
if [ ! -d "$TC_DIR" ]; then
	echo "Downloading clang toolchain..."
	curl -L "$TC_URL" -o toolchain.tar.gz
	mkdir "$TC_DIR"
	tar -xzf toolchain.tar.gz -C "$TC_DIR"
	rm -rf toolchain.tar.gz
else
	echo "Clang toolchain found, Skipping..."
fi

echo "----------------------------------------------"