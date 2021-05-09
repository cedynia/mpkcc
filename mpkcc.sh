#! /bin/bash

root="$(dirname "$0")"
. "$root/global/global_var.sh"
. "$root/global/global_fun.sh"

if [ $# -eq 0 ]
then
 echo "No arguments supplied. The following arguments are required: --api= --arch= "
 exit 1;
fi

store_vars "$1" "$2"

checkFold "$ARCHIVE_FOLDER"
checkFold "$BUILD_FOLDER"
checkFold "$OUTPUT_FOLDER"
rm -rf "android-toolchain*"

echo "Validate links..."
checkArchs

if [ ! $ARCH = "x86_64_PC" ];then
  if [ "$ARCH" == "arm" ];then
    ARCH_NDK=arm
  elif [ "$ARCH" == "arm64" ];then
    ARCH_NDK=arm64
  elif [ "$ARCH" == "x86_64" ];then
    ARCH_NDK=x86_64
  elif [ "$ARCH" == "x86" ];then
    ARCH_NDK=x86
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

. "$root/comp/comp.sh"
cd $MYPWD
