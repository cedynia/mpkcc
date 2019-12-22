#! /bin/bash

global="$(dirname "$0")"
. "$global/global_var.sh"
. "$global/global_fun.sh"
. "$global/osm_var.sh"

checkFold "$ARCHIVE_FOLDER"
checkFold "$BUILD_FOLDER"
checkFold "$OUTPUT_FOLDER"

checkArchs
store_vars

echo $NDK_ROOT
echo $API_VERSION
echo $ARCH

if [ "$ARCH" == "arm" ];then
  ARCH_NDK=arm
  ARCHQT=armeabi-v7a
elif [ "$ARCH" == "arm64" ];then
  ARCH_NDK=arm64
  ARCHQT=arm64-v8a
elif [ "$ARCH" == "x86_64" ];then
  ARCH_NDK=x86_64
  ARCHQT=x86_64
elif [ "$ARCH" == "x86" ];then
  ARCH_NDK=x86
  ARCHQT=x86
fi

TOOLCHAIN_FOLDER=android-toolchain-API$API_VERSION-$ARCH_NDK

if [ -d $TOOLCHAIN_FOLDER ];then
	echo "no need to build one"
else
	make_toolchain
fi

TOOLCHAIN_PATH=$MYPWD/$TOOLCHAIN_FOLDER/bin/
CC_COMPILER=$TOOLCHAIN_PATH/clang
CXX_COMPILER=$TOOLCHAIN_PATH/clang++
export CC=$CC_COMPILER
export CXX=$CXX_COMPILER

global="$(dirname "$0")"
. "$global/script_dev.sh"
cd $MYPWD
global="$(dirname "$0")"
. "$global/build_osmscout-serv.sh"
