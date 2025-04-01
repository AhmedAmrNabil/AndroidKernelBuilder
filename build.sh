#!/bin/bash
#
# Ascendia Build Script - a52sxq
# Coded by BlackMesa123 @2023
# Modified and adapted by RisenID @2024
# Modified by btngana24680 @2025
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

set -e

# Change this according to what you need
DATE=`date +%Y-%m-%d`
ANDROID_CODENAME="U"
RELEASE_VERSION="btngana"
# Clang 11 r383902b1 is suggested
TC_DIR=$(pwd)/toolchain

# ! DON'T CHANGE THESE !
SRC_DIR=$(pwd)/kernel_samsung_ascendia_sm7325
OUT_DIR=$(pwd)/build
MAIN_DIR=$(pwd)
JOBS=4

KSU_VER=$(git -C $SRC_DIR/KernelSU-Next describe --tags | head -n 1)

MAKE_PARAMS="-j$JOBS -C $SRC_DIR O=$SRC_DIR/out \
	ARCH=arm64 CLANG_TRIPLE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
	CROSS_COMPILE=$TC_DIR/bin/llvm-"

export PATH="$TC_DIR/bin:$(pwd):$PATH"
# ! DON'T CHANGE THESE !


DETECT_BRANCH()
{
	cd $SRC_DIR/
	if test "$(git rev-parse --abbrev-ref HEAD)" = oneui-ksu; then
		echo "----------------------------------------------"
		echo "OneUI Branch Detected..."
		ASC_VARIANT="OneUI"
		ASC_VAR="O"
	elif test "$(git rev-parse --abbrev-ref HEAD)" = aosp-ksu; then
		echo "----------------------------------------------"
		echo "AOSP Branch Detected..."
		ASC_VARIANT="AOSP"
		ASC_VAR="A"
	else
		echo "----------------------------------------------"
		echo "Check Branch..."
		exit
	fi
	cd $MAIN_DIR/
}

## Now let's handle this ourselves
CLEAN_SOURCE()
{
	echo "----------------------------------------------"
	echo "Cleaning up sources..."
	rm -rf $SRC_DIR/out
}

BUILD_KERNEL()
{
	echo "----------------------------------------------"
	[ -d "$SRC_DIR/out" ] && echo "Starting $VARIANT kernel build... (DIRTY)" || echo "Starting $VARIANT kernel build..."
	echo " "
	export LOCALVERSION="-$ANDROID_CODENAME-$RELEASE_VERSION-$KSU_VER-$ASC_VAR-$VARIANT"
	mkdir -p $SRC_DIR/out
	rm -rf $SRC_DIR/out/arch/arm64/boot/dts/samsung
	make $MAKE_PARAMS CC="ccache clang" vendor/$DEFCONFIG
	echo " "
	# Regen defconfig
	#cp $SRC_DIR/out/.config $SRC_DIR/arch/arm64/configs/vendor/$DEFCONFIG
	# Make kernel
	make $MAKE_PARAMS CC="ccache clang"
	echo " "
}

REGEN_DEFCONFIG()
{
	echo "----------------------------------------------"
	[ -d "$SRC_DIR/out" ] && echo "Starting $VARIANT kernel build... (DIRTY)" || echo "Starting $VARIANT kernel build..."
	echo " "
	mkdir -p $SRC_DIR/out
	rm -rf $SRC_DIR/out/arch/arm64/boot/dts/samsung
	rm -f $SRC_DIR/out/.config
	make $MAKE_PARAMS CC="ccache clang" vendor/$DEFCONFIG
	echo " "
	# Regen defconfig
	cp $SRC_DIR/out/.config $SRC_DIR/arch/arm64/configs/vendor/$DEFCONFIG
	echo " "
}

BUILD_MODULES()
{
	echo "----------------------------------------------"
	echo "Building kernel modules..."
	echo " "
	make $MAKE_PARAMS INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install
	echo " "
	mkdir -p $OUT_DIR/out/zip/vendor/lib/modules
	find $SRC_DIR/out/modules -name '*.ko' -exec cp '{}' $OUT_DIR/out/zip/vendor/lib/modules ';'
	cp $SRC_DIR/out/modules/lib/modules/5.4*/modules.{alias,dep,softdep} $OUT_DIR/out/zip/vendor/lib/modules
	cp $SRC_DIR/out/modules/lib/modules/5.4*/modules.order $OUT_DIR/out/zip/vendor/lib/modules/modules.load
	sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' $OUT_DIR/out/zip/vendor/lib/modules/modules.dep
	sed -i 's/.*\///g' $OUT_DIR/out/zip/vendor/lib/modules/modules.load
	rm -rf $SRC_DIR/out/modules
}

PACK_BOOT_IMG()
{
	echo "----------------------------------------------"
	echo "Packing $VARIANT boot.img..."
	rm -rf $OUT_DIR/tmp/
	mkdir $OUT_DIR/tmp/
	# Copy and unpack stock boot.img
	cp $OUT_DIR/a52s/$IMG_FOLDER/boot.img $OUT_DIR/tmp/boot.img
	cd $OUT_DIR/tmp/
	avbtool erase_footer --image boot.img
	magiskboot_x86 unpack boot.img
	# Replace stock kernel image
	rm -f $OUT_DIR/tmp/kernel
	cp $SRC_DIR/out/arch/arm64/boot/Image $OUT_DIR/tmp/kernel
	# SELinux permissive
	#CMDLINE=$(cat $OUT_DIR/tmp/split_img/boot.img-cmdline)
	#CMDLINE+=" androidboot.selinux=permissive"
	#echo $CMDLINE > $OUT_DIR/tmp/split_img/boot.img-cmdline
	# Repack and copy in out folder
	magiskboot_x86 repack boot.img boot_new.img
	mv $OUT_DIR/tmp/boot_new.img $OUT_DIR/out/zip/mesa/$IMG_FOLDER/boot.img
	# Clean :3
	rm -rf $OUT_DIR/tmp/
	cd $MAIN_DIR/
}

PACK_BOOT_IMG_PATCH()
{
	echo "----------------------------------------------"
	echo "Packing $VARIANT boot.img.p..."
	rm -rf $OUT_DIR/tmp/
	mkdir $OUT_DIR/tmp/
	# Copy and unpack stock boot.img
	cp $OUT_DIR/a52s/$IMG_FOLDER/boot.img $OUT_DIR/tmp/boot.img
	cd $OUT_DIR/tmp/
	avbtool erase_footer --image boot.img
	magiskboot_x86 unpack boot.img
	# Replace stock kernel image
	rm -f $OUT_DIR/tmp/kernel
	cp $SRC_DIR/out/arch/arm64/boot/Image $OUT_DIR/tmp/kernel
	# SELinux permissive
	#CMDLINE=$(cat $OUT_DIR/tmp/split_img/boot.img-cmdline)
	#CMDLINE+=" androidboot.selinux=permissive"
	#echo $CMDLINE > $OUT_DIR/tmp/split_img/boot.img-cmdline
	# Repack and copy in out folder
	magiskboot_x86 repack boot.img boot_new.img
	bsdiff $OUT_DIR/out/zip/mesa/eur/boot.img $OUT_DIR/tmp/boot_new.img $OUT_DIR/out/zip/mesa/$IMG_FOLDER/boot.img.p
	# Clean :3
	rm -rf $OUT_DIR/tmp/
	cd $MAIN_DIR/
}

PACK_DTBO_IMG()
{
	echo "----------------------------------------------"
	echo "Packing $VARIANT dtbo.img..."
	# Uncomment this to use firmware extracted dtbo
	#cp $OUT_DIR/a52s/$IMG_FOLDER/dtbo.img $OUT_DIR/out/zip/mesa/$IMG_FOLDER/dtbo.img
	cp $SRC_DIR/out/arch/arm64/boot/dtbo.img $OUT_DIR/out/zip/mesa/$IMG_FOLDER/dtbo.img
}

PACK_VENDOR_BOOT_IMG()
{
	echo "----------------------------------------------"
	echo "Packing $VARIANT vendor_boot.img..."
	rm -rf $OUT_DIR/tmp/
	mkdir $OUT_DIR/tmp/
	# Copy and unpack stock vendor_boot.img
	cp $OUT_DIR/a52s/$IMG_FOLDER/vendor_boot.img $OUT_DIR/tmp/vendor_boot.img
	cd $OUT_DIR/tmp/
	avbtool erase_footer --image vendor_boot.img
	magiskboot_x86 unpack -h vendor_boot.img
	# Replace KernelRPValue
	sed '1 c\name='"$RP_REV"'' header > header_new
	rm -f header
	mv header_new header
	# Replace stock DTB
	rm -f $OUT_DIR/tmp/dtb
	cp $SRC_DIR/out/arch/arm64/boot/dts/vendor/qcom/yupik.dtb $OUT_DIR/tmp/dtb
	# SELinux permissive
	#CMDLINE=$(cat $OUT_DIR/tmp/split_img/vendor_boot.img-vendor_cmdline)
	#CMDLINE+=" androidboot.selinux=permissive"
	#echo $CMDLINE > $OUT_DIR/tmp/split_img/vendor_boot.img-vendor_cmdline
	# Repack and copy in out folder
	magiskboot_x86 repack vendor_boot.img vendor_boot_new.img
	mv $OUT_DIR/tmp/vendor_boot_new.img $OUT_DIR/out/zip/mesa/$IMG_FOLDER/vendor_boot.img
	# Clean :3
	rm -rf $OUT_DIR/tmp/
	cd $MAIN_DIR/
}

MAKE_INSTALLER()
{
	cp $OUT_DIR/a52s/update-binary $OUT_DIR/out/zip/META-INF/com/google/android/update-binary
	cp $OUT_DIR/a52s/updater-script $OUT_DIR/out/zip/META-INF/com/google/android/updater-script
	sed -i -e "s/ksu_version/$KSU_VER/g" $OUT_DIR/out/zip/META-INF/com/google/android/update-binary
	sed -i "s/build_date/$DATE/g" $OUT_DIR/out/zip/META-INF/com/google/android/update-binary
	cd $OUT_DIR/out/zip/
	zip -r $OUT_DIR/Builds/${RELEASE_VERSION}_${KSU_VER}_${ASC_VARIANT}_a52sxq.zip mesa META-INF
}

# Do stuff
clear

rm -rf $OUT_DIR/out
rm -f $OUT_DIR/tmp/*.img

mkdir -p $OUT_DIR/out
cp -r $OUT_DIR/zip-template $OUT_DIR/out/zip
mkdir -p $OUT_DIR/out/zip/mesa/eur
mkdir -p $OUT_DIR/out/zip/mesa/chn
mkdir -p $OUT_DIR/out/zip/mesa/kor
mkdir -p $OUT_DIR/Builds/

# a52sxqxx
IMG_FOLDER=eur
VARIANT=a52sxqxx
DEFCONFIG=a52sxq_eur_open_defconfig
RP_REV=SRPUE26A001
if [[ $1 = "-c" || $1 = "--clean" ]]; then
	CLEAN_SOURCE
fi
DETECT_BRANCH
BUILD_KERNEL
PACK_BOOT_IMG
PACK_DTBO_IMG
PACK_VENDOR_BOOT_IMG

# Building for china and korean versions
# WARINING: Untested

# # a52sxqks
# IMG_FOLDER=kor
# VARIANT=a52sxqks
# DEFCONFIG=a52sxq_kor_single_defconfig
# RP_REV=SRPUF22A001
# BUILD_KERNEL
# PACK_BOOT_IMG
# PACK_DTBO_IMG
# PACK_VENDOR_BOOT_IMG

# # a52sxqzt
# IMG_FOLDER=chn
# VARIANT=a52sxqzt
# DEFCONFIG=a52sxq_chn_tw_defconfig
# RP_REV=SRPUE26A001
# BUILD_KERNEL
# PACK_BOOT_IMG
# PACK_DTBO_IMG
# PACK_VENDOR_BOOT_IMG

MAKE_INSTALLER

rm -rf $OUT_DIR/out/

echo "----------------------------------------------"
