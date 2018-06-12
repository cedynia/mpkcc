#!/bin/sh
#this script build the mapnik c++ library for the android system
#there will be an error while building xml it's ok.... libs are generated

NDK_ROOT=
API_VERSION=
MYPWD=${PWD}
TOOLCHAIN_FOLDER=
TOOLCHAIN_PATH=
CC_COMPILER=
CXX_COMPILER=
BUILD=arm-linux-androideabi

BOOST_FOLDER=boost_1_64_0
BOOST_VERSION=1.64.0
BOOST_OUTPUT=boost

ZLIB_FOLDER=zlib-1.2.11
ZLIB_OUTPUT=zlib

LIBXML_FOLDER=libxml2-2.9.0
LIBXML_OUTPUT=libxml2

LIBTIFF_FOLDER=tiff-4.0.9
LIBTIFF_OUTPUT=libtiff

LIBJPEG_FOLDER=jpegsrc.v9c
LIBJPEG_OUTPUT=libjpeg

#hardcoded ftp link
LIBPNG_FOLDER=libpng-1.2.59
LIBPNG_OUTPUT=libpng

LIBPROJ_FOLDER=proj-4.5.0
LIBPROJ_OUTPUT=libproj

LIBFREETYPE_FOLDER=freetype-2.9
LIBFREETYPE_OUTPUT=libfreetype

LIBHARFBUZZ_FOLDER=harfbuzz-1.8.0
LIBHARFBUZZ_OUTPUT=libharfbuzz

LIBICU_FOLDER=icu4c-50_1_2-src
LIBICU_VERSION=50.1.2
LIBICU_OUTPUT=libicu

MAPNIK_VERSION=3.0.20

#uncoment the line if you want to try to build the official master
MAPNIK_MASTER=https://github.com/mapnik/mapnik.git
#...or the snapshot master from VI 2018
#MAPNIK_MASTER=https://gitlab.com/czysty/mapnik_snapshot_master.git

################################################################################

read -p "specify the ndk root folder path: " NDK_ROOT

echo $NDK_ROOT

read -p "specify the api version: " API_VERSION

echo $API_VERSION

TOOLCHAIN_FOLDER=android-toolchain-API$API_VERSION-32

echo "the standalone toolchain will be build in this directory... in:"  $TOOLCHAIN_FOLDER

$NDK_ROOT/build/tools/make_standalone_toolchain.py --arch=arm --api=$API_VERSION --stl=libc++ --force --verbose --install-dir=$MYPWD/$TOOLCHAIN_FOLDER

TOOLCHAIN_PATH=$MYPWD/$TOOLCHAIN_FOLDER/bin/
export CC_COMPILER=$TOOLCHAIN_PATH/clang
export CXX_COMPILER=$TOOLCHAIN_PATH/clang++

echo "toolchain path is: " $TOOLCHAIN_PATH

echo "downloading the actual boost lirary...."

wget https://dl.bintray.com/boostorg/release/$BOOST_VERSION/source/$BOOST_FOLDER.tar.gz

echo "extracting boost"

tar -xvf $BOOST_FOLDER.tar.gz

cd $BOOST_FOLDER

export PATH=$TOOLCHAIN_PATH:$PATH

patch libs/filesystem/src/operations.cpp < ../patches/boost_filesystem.patch

./bootstrap.sh

./b2 install --prefix=$MYPWD/$BOOST_OUTPUT toolset=clang-android target-os=android --with-system --with-thread --with-regex --with-program_options --with-filesystem

cd $MYPWD


wget https://zlib.net/$ZLIB_FOLDER.tar.xz

tar -xvf $ZLIB_FOLDER.tar.xz

cd $ZLIB_FOLDER

./configure --prefix=$MYPWD/$ZLIB_OUTPUT --static

make install -j2

cd $MYPWD

wget ftp://xmlsoft.org/libxml2/$LIBXML_FOLDER.tar.gz

tar -xvf $LIBXML_FOLDER.tar.gz
# #make will fail because android < 28 doesnt have glob and globfree functions
# #but they are required only for tests, so we have to manually copy static libs from .lib folder
# #to our libxml2 folder
mkdir $MYPWD/$LIBXML_OUTPUT/
mkdir $MYPWD/$LIBXML_OUTPUT/lib

cd $LIBXML_FOLDER
./configure --host=$BUILD --prefix=$MYPWD/$LIBXML_OUTPUT

make install -j2

cp .libs/libxml2.a $MYPWD/$LIBXML_OUTPUT/lib/

cd $MYPWD


wget https://download.osgeo.org/libtiff/$LIBTIFF_FOLDER.tar.gz

tar -xvf $LIBTIFF_FOLDER.tar.gz

cd $LIBTIFF_FOLDER

./configure --host=arm-linux --enable-static --prefix=$MYPWD/$LIBTIFF_OUTPUT

make install -j2

cd $MYPWD

wget http://www.ijg.org/files/$LIBJPEG_FOLDER.tar.gz

tar -xvf $LIBJPEG_FOLDER.tar.gz

#hardcoded dont change that!!!!
cd jpeg-9c

./configure --host=arm-linux --enable-static --prefix=$MYPWD/$LIBJPEG_OUTPUT

make install -j2

cd $MYPWD


wget http://ftp-osl.osuosl.org/pub/libpng/src/libpng12/$LIBPNG_FOLDER.tar.gz

tar -xvf $LIBPNG_FOLDER.tar.gz

cd $LIBPNG_FOLDER

./configure --enable-static --prefix=$MYPWD/$LIBPNG_OUTPUT --host=arm-linux-androideabi

make install -j2

cd $MYPWD

wget https://download.osgeo.org/proj/$LIBPROJ_FOLDER.tar.gz

tar -xvf $LIBPROJ_FOLDER.tar.gz

cd $LIBPROJ_FOLDER

./configure --enable-static --prefix=$MYPWD/$LIBPROJ_OUTPUT --host=arm-linux

make install -j2

cd $MYPWD

wget https://download.savannah.gnu.org/releases/freetype/$LIBFREETYPE_FOLDER.tar.gz

tar -xvf $LIBFREETYPE_FOLDER.tar.gz

cd $LIBFREETYPE_FOLDER

./configure --enable-static --prefix=$MYPWD/$LIBFREETYPE_OUTPUT --host=arm-linux-androideabi  --without-harfbuzz --without-zlib --without-png

make install -j2

# #harfbuzz hack allows to find freetype includes
cp -r $MYPWD/$LIBFREETYPE_OUTPUT/include/freetype2/* $MYPWD/$LIBFREETYPE_OUTPUT/include/

cd $MYPWD

wget https://www.freedesktop.org/software/harfbuzz/release/$LIBHARFBUZZ_FOLDER.tar.bz2

tar -xvf $LIBHARFBUZZ_FOLDER.tar.bz2

cd $LIBHARFBUZZ_FOLDER

patch ./configure < ../patches/harfbuzz_freetype.patch

./configure --prefix=$MYPWD/$LIBHARFBUZZ_OUTPUT --host=arm-linux-androideabi PKG_CONFIG='' CPPFLAGS=-I$MYPWD/$LIBFREETYPE_OUTPUT/include/  LDFLAGS=-L$MYPWD/$LIBFREETYPE_OUTPUT/lib/ FREETYPE_LIBS=$MYPWD/$LIBFREETYPE_OUTPUT/lib/libfreetype.so  --enable-static  --without-icu

make install -j2

cd $MYPWD

wget http://download.icu-project.org/files/icu4c/$LIBICU_VERSION/$LIBICU_FOLDER.tgz

tar -xvf $LIBICU_FOLDER.tgz

# #!!!!!!!!!!!!!!!!HARDCODING ALERT
cd icu

patch source/common/ucnvmbcs.c < ../patches/icu_50_1_2_ucnvmbcs.patch
patch source/i18n/uspoof.cpp < ../patches/icu_50_1_2_uspoof.patch

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

../source/configure --host=arm-linux-androideabi --with-cross-build=$MYPWD/icu/dirA/ --enable-static --disable-shared --prefix=$MYPWD/libicu

make install -j2

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
cp -r $MYPWD/mapnik/deps/mapbox/variant/include/mapbox/*  $MYPWD/mapnik-lib/include/mapbox/variant/
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
echo "**************************************************************************************"
