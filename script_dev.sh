#! /bin/bash


global_var="$(dirname "$0")"
. "$global_var/global_var.sh"
global_fun="$(dirname "$0")"
. "$global_fun/global_fun.sh"

if [ $# -eq 0 ]
  then
    echo "No arguments supplied. The following arguments are required: --ndk-root= --api= "
		exit 1;
fi

checkFold "$ARCHIVE_FOLDER"
checkFold "$BUILD_FOLDER"
checkFold "$OUTPUT_FOLDER"

for A in ${!archArray[@]};
do
	echo ${A}
	if [ -f $ARCHIVE_FOLDER/$A ];then echo $A 'exist!';archArray[$A]=true; fi
done

for A in ${archArray[@]};
do
	echo ${A}
done

echo "checking links availability..."

for arch in ${!archArray[@]};
do
	if [ ${archArray[$arch]} = false ] && ! validateLink ${linksArray[$arch]} ;then
		echo "the download link for $arch is not responding, please download $arch manually to $ARCHIVE_FOLDER folder";
		exit 1;
	fi
done

for i in "$@"
do
case $i in
    --ndk-root=*)
    NDK_ROOT="${i#*=}"
    shift # past argument=value
    ;;
    --api=*)
    API_VERSION="${i#*=}"
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

TOOLCHAIN_FOLDER=android-toolchain-API$API_VERSION-32

if [ -d $TOOLCHAIN_FOLDER ];then
	echo "no need to build one"
else
	echo "copying toolchain to: "  $TOOLCHAIN_FOLDER
	$NDK_ROOT/build/tools/make_standalone_toolchain.py \
		--arch=arm \
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

#############BOOST
cd $MYPWD

cdIntoSrc "$BOOST_FOLDER"

export PATH=$TOOLCHAIN_PATH:$PATH
patch libs/filesystem/src/operations.cpp < $MYPWD/patches/boost_filesystem.patch
patch libs/filesystem/src/operations.cpp < $MYPWD/patches/boost_operations.patch

./bootstrap.sh
./b2 install \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$BOOST_OUTPUT \
	  toolset=clang-android \
		target-os=android \
		--with-system \
		--with-thread \
		--with-regex \
		--with-program_options \
		--with-filesystem

###########ZLIB
cd $MYPWD


cdIntoSrc "$ZLIB_FOLDER"

./configure \
	--prefix=$MYPWD/$OUTPUT_FOLDER/$ZLIB_OUTPUT \
	--static

make install -j$NPROC

###########LIBXML
cd $MYPWD

cdIntoSrc "$LIBXML_FOLDER"

./configure \
		--host=$BUILD \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBXML_OUTPUT \
		--without-zlib \
		--without-lzma \
		--without-python \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j$NPROC

############LIBTIFF
cd $MYPWD

cdIntoSrc "$LIBTIFF_FOLDER"

./configure \
		--host=arm-linux \
		--enable-static \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBTIFF_OUTPUT \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER
		CFLAGS=-fexceptions

make install -j$NPROC

###########LIBJPEG
cd $MYPWD

cdIntoSrc "$LIBJPEG_FOLDER"

./configure \
		--host=arm-linux \
		--enable-static \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBJPEG_OUTPUT \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER \
		CFLAGS=-fexceptions

make install -j$NPROC

############LIBPNG
cd $MYPWD

cdIntoSrc "$LIBPNG_FOLDER"

./configure \
		--enable-static \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBPNG_OUTPUT \
		--host=arm-linux-androideabi \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER
		CFLAGS=-fexceptions

make install -j$NPROC

#############LIBPROJ
cd $MYPWD

cdIntoSrc "$LIBPROJ_FOLDER"

./configure \
			--enable-static \
			--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBPROJ_OUTPUT \
			--host=arm-linux \
			CC=$CC_COMPILER \
			CXX=$CXX_COMPILER

make install -j$NPROC

#############LIBFREETYPE
cd $MYPWD


cdIntoSrc "$LIBFREETYPE_FOLDER"

./configure \
			--enable-static \
			--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT \
			--host=arm-linux-androideabi  \
			--without-harfbuzz \
			--without-zlib \
			--without-png \
			CC=$CC_COMPILER \
			CXX=$CXX_COMPILER

make install -j$NPROC

# #harfbuzz hack allows to find freetype includes
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/freetype2/* $MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/

############LIBHARFBUZZ
cd $MYPWD

cdIntoSrc "$LIBHARFBUZZ_FOLDER"

patch ./configure < $MYPWD/patches/harfbuzz_freetype.patch

./configure \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBHARFBUZZ_OUTPUT \
		--host=arm-linux-androideabi \
		PKG_CONFIG='' \
		CPPFLAGS=-I$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/  \
		LDFLAGS=-L$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/lib/ \
		FREETYPE_LIBS=$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/lib/libfreetype.so  \
		--enable-static  \
		--without-icu \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j$NPROC

#############LIBICU
cd $MYPWD

cdIntoSrc "$LIBICU_FOLDER"

patch source/common/ucnvmbcs.c < $MYPWD/patches/icu_50_1_2_ucnvmbcs.patch
patch source/i18n/uspoof.cpp < $MYPWD/patches/icu_50_1_2_uspoof.patch

mkdir dirA
mkdir dirB

cd dirA

export CC=gcc
export CXX=g++

../source/runConfigureICU Linux --enable-static --disable-shared

make

cd ../dirB

export CC=$CC_COMPILER
export CXX=$CXX_COMPILER

../source/configure \
		--host=arm-linux-androideabi \
		--with-cross-build=$(pwd)/../dirA/ \
		--enable-static \
		--disable-shared \
		--prefix=$MYPWD/$OUTPUT_FOLDER/libicu

make install -j$NPROC

#############MAPNIK
cd $MYPWD

git clone $MAPNIK_MASTER mapnik
cd $MYPWD/mapnik/
git checkout v3.0.20
git submodule update --init deps/mapbox/

patch SConstruct < $MYPWD/patches/mapnik_scons.patch
patch Makefile <  $MYPWD/patches/mapnik_makefile.patch
patch include/mapnik/value_types.hpp <  $MYPWD/patches/mapnik_value_types.patch
#need to patch readers for png and jpeg for remove the anonymous namespace that wraps create_jpeg_reader and create_tiff_reader fn
patch src/jpeg_reader.cpp < $MYPWD/patches/jpeg_reader.patch
patch src/png_reader.cpp < $MYPWD/patches/png_reader.patch
#no need to do the same with tiff_reader.cpp beacause we include the file in the project
#doing the same with png reader generates an error (redefinition of the global function)
#patch src/tiff_reader.cpp < $MYPWD/patches/tiff_reader.patch

echo "
CC='$CC_COMPILER'
CXX='$CXX_COMPILER'
CUSTOM_DEFINES='-DHAVE_JPEG -DHAVE_TIFF -DHAVE_PNG'
RUNTIME_LINK='static'
CUSTOM_CXXFLAGS = '-DU_HAVE_STD_STRING=1'
LINKING='static'
INPUT_PLUGINS='shape'
BOOST_INCLUDES ='$MYPWD/$OUTPUT_FOLDER/$BOOST_OUTPUT/include'
BOOST_LIBS ='$MYPWD/$OUTPUT_FOLDER/$BOOST_OUTPUT/lib'
ICU_INCLUDES ='$MYPWD/$OUTPUT_FOLDER/$LIBICU_OUTPUT/include/'
ICU_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBICU_OUTPUT/lib/'
HB_INCLUDES = '$MYPWD/$OUTPUT_FOLDER/$LIBHARFBUZZ_OUTPUT/include/'
HB_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBHARFBUZZ_OUTPUT/lib'
PNG_INCLUDES = '$MYPWD/$OUTPUT_FOLDER/$LIBPNG_OUTPUT/include'
PNG_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBPNG_OUTPUT/lib'
JPEG_INCLUDES = '$MYPWD/$OUTPUT_FOLDER/$LIBJPEG_OUTPUT/include'
JPEG_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBJPEG_OUTPUT/lib'
TIFF_INCLUDES = '$MYPWD/$OUTPUT_FOLDER/$LIBTIFF_OUTPUT/include'
TIFF_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBTIFF_OUTPUT/lib'
WEBP_INCLUDES = ''
WEBP_LIBS = ''
PROJ_INCLUDES = '$MYPWD/$OUTPUT_FOLDER/$LIBPROJ_OUTPUT/include'
PROJ_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBPROJ_OUTPUT/lib'
FREETYPE_INCLUDES = '$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/freetype2'
FREETYPE_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/lib/'
XML2_INCLUDES = '$MYPWD/$OUTPUT_FOLDER/$LIBXML_OUTPUT/include'
XML2_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBXML_OUTPUT/lib'
CPP_TESTS = False
OCCI_INCLUDES = ''
OCCI_LIBS = ''
SQLITE_INCLUDES = ''
SQLITE_LIBS = ''
RASTERLITE_INCLUDES = ''
PLUGIN_LINKING = 'static'
ENABLE_SONAME = False
MAPNIK_INDEX = False
JOBS=$NPROC

" > config.py

python scons/scons.py -j$NPROC

cd $MYPWD

mkdir -p $MYPWD/$MAPNIK_OUTPUT/lib/
mkdir -p $MYPWD/$MAPNIK_OUTPUT/include/mapbox/variant/

cd $MYPWD
find $MYPWD/$OUTPUT_FOLDER/$BOOST_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$LIBICU_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$LIBHARFBUZZ_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$LIBPNG_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$LIBJPEG_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$LIBTIFF_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$LIBPROJ_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$LIBXML_OUTPUT/lib/*.a \
		$MYPWD/$OUTPUT_FOLDER/$ZLIB_OUTPUT/lib/*.a \
-exec cp {} $MYPWD/$MAPNIK_OUTPUT/lib/ ";"

find $MYPWD/mapnik/ -name *.a -exec cp {} $MYPWD/mapnik-lib/lib/ ";"

cp -r $MYPWD/mapnik/include/  $MYPWD/$MAPNIK_OUTPUT/
cp -r $MYPWD/mapnik/deps/mapbox/variant/include/mapbox/*  $MYPWD/$MAPNIK_OUTPUT/include/mapbox/
cp -r $MYPWD/$OUTPUT_FOLDER/$BOOST_OUTPUT/include/  $MYPWD/$MAPNIK_OUTPUT/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBHARFBUZZ_OUTPUT/include/ $MYPWD/$MAPNIK_OUTPUT/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBICU_OUTPUT/include/ $MYPWD/$MAPNIK_OUTPUT/
cp    $MYPWD/$OUTPUT_FOLDER/$LIBTIFF_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include/mapnik/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBPROJ_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include/mapnik/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include/mapnik/text/
cp    $MYPWD/mapnik/deps/agg/include/* $MYPWD/$MAPNIK_OUTPUT/include/mapnik/
#tiff_reader.cpp
cp    $MYPWD/mapnik/src/tiff_reader.cpp $MYPWD/$MAPNIK_OUTPUT/include/mapnik/
cp -r $MYPWD/mapnik/deps/mapnik/sparsehash/ $MYPWD/$MAPNIK_OUTPUT/include/mapnik/

cd $MYPWD/$MAPNIK_OUTPUT/lib/

echo "
create libmapnik4android.a
addlib libboost_filesystem.a
addlib libboost_program_options.a
addlib libboost_regex.a
addlib libboost_system.a
addlib libboost_thread.a
addlib libfreetype.a
addlib libharfbuzz-subset.a
addlib libharfbuzz.a
addlib libicudata.a
addlib libicui18n.a
addlib libicuio.a
addlib libicule.a
addlib libiculx.a
addlib libicutest.a
addlib libicutu.a
addlib libicuuc.a
addlib libjpeg.a
addlib libmapnik.a
addlib libpng.a
addlib libproj.a
addlib libtiff.a
addlib libxml2.a
addlib libz.a
addlib libmapnik-json.a
addlib libmapnik-wkt.a
save
end
" > mri_script

ar -M < mri_script

echo "*****************ADD THIS TO YOUR CMAKELISTS IN ANDROIDSTUDIO PROJECT*****************"
echo "**************************************************************************************"
echo "
################################################################
add_library(mapnik STATIC IMPORTED)
set_target_properties(mapnik PROPERTIES IMPORTED_LOCATION
    $MYPWD/mapnik-lib/lib/libmapnik4android.a)
include_directories($MYPWD/mapnik-lib/include/)
################################################################
"
echo "**************************************************************************************"#
