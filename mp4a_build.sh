#! /bin/bash

global="$(dirname "$0")"
. "$global/global_var.sh"
. "$global/global_fun.sh"
. "$global/osm_var.sh"

#echo "$1"
#echo "$2"

store_vars "$1" "$2"
echo "Validate links..."

checkFold "$ARCHIVE_FOLDER"
checkFold "$BUILD_FOLDER"
checkFold "$OUTPUT_FOLDER"
rm -rf "android-toolchain*"
checkArchs

#echo $NDK_ROOT
#echo $API_VERSION
#echo $ARCH

if [ ! $ARCH = "x86_64_PC" ];then
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
  make_toolchain
  NDK_ROOT=$MYPWD/$BUILD_FOLDER/ndk/android-ndk-$NDK_VER/
  TOOLCHAIN_PATH=$MYPWD/$TOOLCHAIN_FOLDER/bin/
  CC_COMPILER=$TOOLCHAIN_PATH/clang
  CXX_COMPILER=$TOOLCHAIN_PATH/clang++
else
  echo "Building for PC"
  CC_COMPILER=gcc
  CXX_COMPILER=g++
  BUILD=
  HOST=
  TOOLSET=
  TARGETOS=linux
  TOOLSET=gcc
fi

export CC=$CC_COMPILER
export CXX=$CXX_COMPILER

global="$(dirname "$0")"
. "$global/script_dev.sh"
cd $MYPWD
# if [ ! $ARCH = "x86_64_PC" ];then
#   global="$(dirname "$0")"
#   . "$global/build_osmscout-serv.sh"
# fi
