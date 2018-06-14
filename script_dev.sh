#! /bin/bash

global_var="$(dirname "$0")"
. "$global_var/global_var.sh"
global_fun="$(dirname "$0")"
. "$global_fun/global_fun.sh"

if [ ! -d .arch ];then
	echo ".arch doesnt exist!";
	mkdir  .arch
else
	echo ".arch exist"
fi

if [ ! -d build ];then
	echo ".arch doesnt exist!";
	mkdir  build
else
	echo "build exist"
fi

for A in ${!archArray[@]};
do
	echo ${A}
	if [ -f .arch/$A ];then echo $A 'exist!';archArray[$A]=true; fi
done

for A in ${archArray[@]};
do
	echo ${A}
done

echo "checking links availability..."

for arch in ${!archArray[@]};
do
	if [ ${archArray[$arch]} = false ] && ! validateLink ${linksArray[$arch]} ;then
		echo "the download link for $arch is not responding, please download $arch manually to .arch folder";
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

./bootstrap.sh
./b2 install \
		--prefix=$MYPWD/$BOOST_OUTPUT \
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
	--prefix=$MYPWD/$ZLIB_OUTPUT \
	--static

make install -j2

###########LIBXML
cd $MYPWD

cdIntoSrc "$LIBXML_FOLDER"

./configure \
		--host=$BUILD \
		--prefix=$MYPWD/$LIBXML_OUTPUT \
		--without-zlib \
		--without-lzma \
		--without-python \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j2

############LIBTIFF
cd $MYPWD


cdIntoSrc "$LIBTIFF_FOLDER"

./configure \
		--host=arm-linux \
		--enable-static \
		--prefix=$MYPWD/$LIBTIFF_OUTPUT \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j2

###########LIBJPEG
cd $MYPWD

cdIntoSrc "$LIBJPEG_FOLDER"

./configure \
		--host=arm-linux \
		--enable-static \
		--prefix=$MYPWD/$LIBJPEG_OUTPUT \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j2

############LIBPNG
cd $MYPWD

cdIntoSrc "$LIBPNG_FOLDER"

./configure \
		--enable-static \
		--prefix=$MYPWD/$LIBPNG_OUTPUT \
		--host=arm-linux-androideabi \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j2

#############LIBPROJ
cd $MYPWD

cdIntoSrc "$LIBPROJ_FOLDER"

./configure \
			--enable-static \
			--prefix=$MYPWD/$LIBPROJ_OUTPUT \
			--host=arm-linux \
			CC=$CC_COMPILER \
			CXX=$CXX_COMPILER

make install -j2

#############LIBFREETYPE
cd $MYPWD


cdIntoSrc "$LIBFREETYPE_FOLDER"

./configure \
			--enable-static \
			--prefix=$MYPWD/$LIBFREETYPE_OUTPUT \
			--host=arm-linux-androideabi  \
			--without-harfbuzz \
			--without-zlib \
			--without-png \
			CC=$CC_COMPILER \
			CXX=$CXX_COMPILER

make install -j2

# #harfbuzz hack allows to find freetype includes
cp -r $MYPWD/$LIBFREETYPE_OUTPUT/include/freetype2/* $MYPWD/$LIBFREETYPE_OUTPUT/include/

############LIBHARFBUZZ
cd $MYPWD


cdIntoSrc "$LIBHARFBUZZ_FOLDER"

patch ./configure < $MYPWD/patches/harfbuzz_freetype.patch

./configure \
		--prefix=$MYPWD/$LIBHARFBUZZ_OUTPUT \
		--host=arm-linux-androideabi \
		PKG_CONFIG='' \
		CPPFLAGS=-I$MYPWD/$LIBFREETYPE_OUTPUT/include/  \
		LDFLAGS=-L$MYPWD/$LIBFREETYPE_OUTPUT/lib/ \
		FREETYPE_LIBS=$MYPWD/$LIBFREETYPE_OUTPUT/lib/libfreetype.so  \
		--enable-static  \
		--without-icu \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j2

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
		--prefix=$MYPWD/libicu

make install -j2

#############MAPNIK
cd $MYPWD

git clone $MAPNIK_MASTER mapnik
cd $MYPWD/mapnik/
git submodule update --init deps/mapbox/

patch include/mapnik/css_color_grammar_x3_def.hpp < $MYPWD/patches/mapnik_css.patch
patch include/mapnik/geometry/strategy.hpp < $MYPWD/patches/mapnik_strategy.patch
patch src/agg/process_line_pattern_symbolizer.cpp < $MYPWD/patches/mapnik_process.patch
patch src/text/color_font_renderer.cpp < $MYPWD/patches/mapnik_color.patch
patch Makefile < $MYPWD/patches/mapnik_makefile.patch
patch SConstruct < $MYPWD/patches/mapnik_sconstruct.patch

echo "
CC='$CC_COMPILER'
CXX='$CXX_COMPILER'
RUNTIME_LINK='static'
LINKING='static'
INPUT_PLUGINS='shape'
BOOST_INCLUDES ='$MYPWD/$BOOST_OUTPUT/include'
BOOST_LIBS ='$MYPWD/$BOOST_OUTPUT/lib'
ICU_INCLUDES ='$MYPWD/$LIBICU_OUTPUT/include/'
ICU_LIBS = '$MYPWD/$LIBICU_OUTPUT/lib/'
HB_INCLUDES = '$MYPWD/$LIBHARFBUZZ_OUTPUT/include/'
HB_LIBS = '$MYPWD/$LIBHARFBUZZ_OUTPUT/lib'
PNG_INCLUDES = '$MYPWD/$LIBPNG_OUTPUT/include'
PNG_LIBS = '$MYPWD/$LIBPNG_OUTPUT/lib'
JPEG_INCLUDES = '$MYPWD/$LIBJPEG_OUTPUT/include'
JPEG_LIBS = '$MYPWD/$LIBJPEG_OUTPUT/lib'
TIFF_INCLUDES = '$MYPWD/$LIBTIFF_OUTPUT/include'
TIFF_LIBS = '$MYPWD/$LIBTIFF_OUTPUT/lib'
WEBP_INCLUDES = ''
WEBP_LIBS = ''
PROJ_INCLUDES = '$MYPWD/$LIBPROJ_OUTPUT/include'
PROJ_LIBS = '$MYPWD/$LIBPROJ_OUTPUT/lib'
FREETYPE_INCLUDES = '$MYPWD/$LIBFREETYPE_OUTPUT/include/freetype2'
FREETYPE_LIBS = '$MYPWD/$LIBFREETYPE_OUTPUT/lib/'
XML2_INCLUDES = '$MYPWD/$LIBXML_OUTPUT/include'
XML2_LIBS = '$MYPWD/$LIBXML_OUTPUT/lib'
CPP_TESTS = False
OCCI_INCLUDES = ''
OCCI_LIBS = ''
SQLITE_INCLUDES = ''
SQLITE_LIBS = ''
RASTERLITE_INCLUDES = ''
PLUGIN_LINKING = 'static'
ENABLE_SONAME = False
MAPNIK_INDEX = False

" > config.py

./configure

make

cd $MYPWD

mkdir -p $MYPWD/mapnik-lib/lib/
mkdir -p $MYPWD/mapnik-lib/include/mapbox/
mkdir -p $MYPWD/mapnik-lib/include/mapbox/geometry/
mkdir -p $MYPWD/mapnik-lib/include/mapbox/variant/

cd $MYPWD
find $MYPWD/$BOOST_OUTPUT/lib/*.a \
$MYPWD/$LIBICU_OUTPUT/lib/*.a \
$MYPWD/$LIBICU_OUTPUT/lib/*.a \
$MYPWD/$LIBHARFBUZZ_OUTPUT/lib/*.a \
$MYPWD/$LIBPNG_OUTPUT/lib/*.a \
$MYPWD/$LIBPNG_OUTPUT/lib/*.a \
$MYPWD/$LIBJPEG_OUTPUT/lib/*.a \
$MYPWD/$LIBTIFF_OUTPUT/lib/*.a \
$MYPWD/$LIBPROJ_OUTPUT/lib/*.a \
$MYPWD/$LIBFREETYPE_OUTPUT/lib/*.a \
$MYPWD/$LIBXML_OUTPUT/lib/*.a \
$MYPWD/$ZLIB_OUTPUT/lib/*.a \
$MYPWD/mapnik/src/*.a \
-exec cp {} $MYPWD/mapnik-lib/lib/ ";"

cp -r $MYPWD/mapnik/include/  $MYPWD/mapnik-lib/
cp -r $MYPWD/mapnik/deps/mapbox/variant/include/mapbox/*  $MYPWD/mapnik-lib/include/mapbox/
cp -r $MYPWD/mapnik/deps/mapbox/geometry/include/mapbox/geometry/*  $MYPWD/mapnik-lib/include/mapbox/geometry/
cp -r $MYPWD/$BOOST_OUTPUT/include/  $MYPWD/mapnik-lib/
cp -r $MYPWD/$LIBHARFBUZZ_OUTPUT/include/ $MYPWD/mapnik-lib/
cp -r $MYPWD/$LIBICU_OUTPUT/include/ $MYPWD/mapnik-lib/


cd $MYPWD/mapnik-lib/lib/

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
    $MYPWD/libmapnik-lib/lib/libmapnik4android.a)
include_directories($MYPWD/libmapnik-lib/include/)
################################################################
"
echo "**************************************************************************************"#
