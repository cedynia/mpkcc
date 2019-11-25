#! /bin/bash

global="$(dirname "$0")"
. "$global/global_var.sh"
. "$global/global_fun.sh"
. "$global/osm_var.sh"


if [ $# -eq 0 ]
  then
    echo "No arguments supplied. The following arguments are required: --ndk-root= --api= --arch= --sdk-root="
		exit 1;
fi

checkFold "$ARCHIVE_FOLDER"
checkFold "$BUILD_FOLDER"
checkFold "$OUTPUT_FOLDER"

checkArchs

for i in "$@"
do
case $i in
    --sdk-root=*)
    SDK_ROOT="${i#*=}"
    shift # past argument=value
    ;;
    --ndk-root=*)
    NDK_ROOT="${i#*=}"
    echo "jest ndk root"
    shift # past argument=value
    ;;
    --api=*)
    API_VERSION="${i#*=}"
    shift # past argument=value
    ;;
    --arch=*)
    ARCH="${i#*=}"
    shift # past argument=value
    ;;
    *)
          echo "unknown option: $i"
					exit 1;
    ;;
esac
done

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
	echo "copying toolchain to: "  $TOOLCHAIN_FOLDER
	$NDK_ROOT/build/tools/make_standalone_toolchain.py \
		--arch=$ARCH_NDK \
		--api=$API_VERSION \
		--stl=libc++ \
		--force \
		--verbose \
		--install-dir=$MYPWD/$TOOLCHAIN_FOLDER
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
