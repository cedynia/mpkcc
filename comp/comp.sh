#! /bin/bash

############LIBMICROHTTP
cd $MYPWD

cdIntoSrc "$LIBMICROHTTP_FOLDER"

CFLAGS="-fPIC" ./configure \
  --host=$BUILD \
	--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBMICROHTTP_OUTPUT \

make install -j$NPROC

checkCompResult "$LIBMICROHTTP_OUTPUT"

###########SQLITE3
cd $MYPWD

cdIntoSrc "$LIBSQLITE3_FOLDER"

CFLAGS="-fPIC" ./configure \
  --host=$BUILD \
	--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBSQLITE3_OUTPUT \

make install -j$NPROC

checkCompResult "$LIBSQLITE3_OUTPUT"

# #############BOOST
cd $MYPWD

cdIntoSrc "$BOOST_FOLDER"


export PATH=$TOOLCHAIN_PATH:$PATH
patch libs/filesystem/src/operations.cpp < $MYPWD/patches/boost_filesystem.patch
patch libs/filesystem/src/operations.cpp < $MYPWD/patches/boost_operations.patch

./bootstrap.sh
./b2 install \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$BOOST_OUTPUT \
	  toolset=$TOOLSET \
		target-os=$TARGETOS \
    link=static \
		--with-system \
		--with-thread \
		--with-regex \
		--with-program_options \
		--with-filesystem \
    cxxflags="-fPIC" \
    cflags="-fPIC"

checkCompResult "$BOOST_OUTPUT"

# ###########ZLIB
cd $MYPWD

cdIntoSrc "$ZLIB_FOLDER"

CFLAGS="-fPIC"  ./configure \
	--prefix=$MYPWD/$OUTPUT_FOLDER/$ZLIB_OUTPUT \
	--static

make install -j$NPROC

checkCompResult "$ZLIB_OUTPUT"

# ###########LIBXML
cd $MYPWD

cdIntoSrc "$LIBXML_FOLDER"

CFLAGS="-fPIC" ./configure \
		--host=$BUILD \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBXML_OUTPUT \
		--without-zlib \
		--without-lzma \
		--without-python \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j$NPROC

checkCompResult "$LIBXML_OUTPUT"

############LIBTIFF
cd $MYPWD

cdIntoSrc "$LIBTIFF_FOLDER"

CFLAGS="-fPIC -fexceptions" ./configure \
		--host=$HOST \
		--enable-static \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBTIFF_OUTPUT \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER
		CFLAGS="-fPIC -fexceptions"


make install -j$NPROC


checkCompResult "$LIBTIFF_OUTPUT"

###########LIBJPEG
cd $MYPWD

cdIntoSrc "$LIBJPEG_FOLDER"

CFLAGS="-fPIC -fexceptions" ./configure \
		--host=$HOST \
		--enable-static \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBJPEG_OUTPUT \
		CC=$CC_COMPILER


make install -j$NPROC

checkCompResult "$LIBJPEG_OUTPUT"

############LIBPNG
cd $MYPWD

cdIntoSrc "$LIBPNG_FOLDER"

CFLAGS="-fPIC -fexceptions" ./configure \
		--enable-static \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBPNG_OUTPUT \
		--host=$BUILD \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER
		CFLAGS="-fPIC -fexceptions"


make install -j$NPROC

checkCompResult "$LIBPNG_OUTPUT"

#############LIBPROJ
cd $MYPWD

cdIntoSrc "$LIBPROJ_FOLDER"

CFLAGS="-fPIC -Wl,-soname=libproj.so" ./configure \
			--enable-static \
			--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBPROJ_OUTPUT \
			--host=$HOST \
			CC=$CC_COMPILER \
			CXX=$CXX_COMPILER

make install -j$NPROC

checkCompResult "$LIBPROJ_OUTPUT"

#############LIBFREETYPE
cd $MYPWD


cdIntoSrc "$LIBFREETYPE_FOLDER"

CFLAGS="-fPIC" ./configure \
			--enable-static \
			--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT \
			--host=$BUILD  \
			--without-harfbuzz \
			--without-zlib \
			--without-png \
			CC=$CC_COMPILER \
			CXX=$CXX_COMPILER

make install -j$NPROC

checkCompResult "$LIBFREETYPE_OUTPUT"

# #harfbuzz hack allows to find freetype includes
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/freetype2/* $MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/

############LIBHARFBUZZ
cd $MYPWD

cdIntoSrc "$LIBHARFBUZZ_FOLDER"

patch ./configure < $MYPWD/patches/harfbuzz_freetype.patch


CXXFLAGS="-fPIC" CFLAGS="-fPIC"  ./configure \
		--prefix=$MYPWD/$OUTPUT_FOLDER/$LIBHARFBUZZ_OUTPUT \
		--host=$BUILD \
		PKG_CONFIG='' \
		CPPFLAGS=-I$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/  \
		LDFLAGS=-L$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/lib/ \
		FREETYPE_LIBS=$MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/lib/libfreetype.so  \
		--enable-static  \
		--without-icu \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j$NPROC

checkCompResult "$LIBHARFBUZZ_OUTPUT"

#############LIBICU
cd $MYPWD

cdIntoSrc "$LIBICU_FOLDER"

mkdir dirA
mkdir dirB

cd dirA

export CC=gcc
export CXX=g++

CFLAGS="-fPIC" ../source/runConfigureICU Linux --enable-static --disable-shared

make -j$NPROC

cd ../dirB

export CC=$CC_COMPILER
export CXX=$CXX_COMPILER

LDFLAGS="-fuse-ld=lld" CXXFLAGS="-fPIC " CFLAGS="-fPIC " ../source/configure \
		--host=$BUILD \
		--with-cross-build=$(pwd)/../dirA/ \
		--enable-static \
		--disable-shared \
		--prefix=$MYPWD/$OUTPUT_FOLDER/libicu


make install -j$NPROC

checkCompResult "$LIBICU_OUTPUT"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MYPWD/$OUTPUT_FOLDER/libicu/lib

#############MAPNIK
cd $MYPWD

git clone $MAPNIK_MASTER $MYPWD/$BUILD_FOLDER/mapnik
cd $MYPWD/$BUILD_FOLDER/mapnik/
git checkout v3.0.21
git submodule update --init deps/mapbox/

patch -p1 < $MYPWD/patches/mapnik_twkb.patch
patch include/mapnik/value_types.hpp <  $MYPWD/patches/mapnik_value_types.patch
patch include/mapnik/markers_placement.hpp < $MYPWD/patches/markers_placement.patch

echo "
CC='$CC_COMPILER'
CXX='$CXX_COMPILER'
RUNTIME_LINK='static'
CAIRO='False'
CUSTOM_LDFLAGS= ''
CUSTOM_CXXFLAGS = '-DU_HAVE_STD_STRING=1 -DMAPNIK_USE_PROJ4 -DHAVE_JPEG -DHAVE_PNG -DHAVE_TIFF'
CUSTOM_LDFLAGS= '-fuse-ld=lld'
LINKING='static'
HOST='$HOST'
INPUT_PLUGINS='shape,sqlite'
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
SQLITE_INCLUDES = '$MYPWD/$OUTPUT_FOLDER/$LIBSQLITE3_OUTPUT/include'
SQLITE_LIBS = '$MYPWD/$OUTPUT_FOLDER/$LIBSQLITE3_OUTPUT/lib'
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
    $MYPWD/$OUTPUT_FOLDER/$LIBSQLITE3_OUTPUT/lib/*.a \
    $MYPWD/$OUTPUT_FOLDER/$LIBMICROHTTP_OUTPUT/lib/*.a \
-exec cp {} $MYPWD/$MAPNIK_OUTPUT/lib/ ";"

find $MYPWD/$BUILD_FOLDER/mapnik/ -name *.a -exec cp {} $MYPWD/$MAPNIK_OUTPUT/lib/ ";"

cp -r $MYPWD/$BUILD_FOLDER/mapnik/include/  $MYPWD/$MAPNIK_OUTPUT/
cp -r $MYPWD/$BUILD_FOLDER/mapnik/deps/mapbox/variant/include/mapbox/*  $MYPWD/$MAPNIK_OUTPUT/include/mapbox/
cp -r $MYPWD/$OUTPUT_FOLDER/$BOOST_OUTPUT/include/  $MYPWD/$MAPNIK_OUTPUT/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBHARFBUZZ_OUTPUT/include/ $MYPWD/$MAPNIK_OUTPUT/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBICU_OUTPUT/include/ $MYPWD/$MAPNIK_OUTPUT/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBTIFF_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBPROJ_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include/mapnik/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBFREETYPE_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include/mapnik/text/
cp -r $MYPWD/$BUILD_FOLDER/mapnik/deps/agg/include/* $MYPWD/$MAPNIK_OUTPUT/include/mapnik/
#tiff_reader.cpp
cp -r $MYPWD/$BUILD_FOLDER/mapnik/src/tiff_reader.cpp $MYPWD/$MAPNIK_OUTPUT/include/mapnik/
cp -r $MYPWD/$BUILD_FOLDER/mapnik/deps/mapnik/sparsehash/ $MYPWD/$MAPNIK_OUTPUT/include/mapnik/
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBSQLITE3_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include
cp -r $MYPWD/$OUTPUT_FOLDER/$LIBMICROHTTP_OUTPUT/include/* $MYPWD/$MAPNIK_OUTPUT/include

cd $MYPWD/$MAPNIK_OUTPUT/lib/

echo "
create libmpkcc.a
addlib libboost_filesystem.a
addlib libboost_program_options.a
addlib libboost_regex.a
addlib libboost_system.a
addlib libboost_thread.a
addlib libfreetype.a
addlib libharfbuzz.a
addlib libicudata.a
addlib libicui18n.a
addlib libicuio.a
addlib libicule.a
addlib libiculx.a
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
addlib libsqlite3.a
addlib libmicrohttpd.a
save
end
" > mri_script

ar -M < mri_script

cd $MYPWD
mkdir -p $RELEASE_FOLDER/lib
cp -r $MYPWD/$MAPNIK_OUTPUT/include $MYPWD/$RELEASE_FOLDER/
cp -r $MYPWD/$MAPNIK_OUTPUT/lib/libmpkcc.a $MYPWD/$RELEASE_FOLDER/lib/

echo "*****************ADD THIS TO YOUR CMAKELISTS IN ANDROIDSTUDIO PROJECT*****************"
echo "**************************************************************************************"
echo "
################################################################
add_library(mapnik STATIC IMPORTED)
set_target_properties(mapnik PROPERTIES IMPORTED_LOCATION
    $MYPWD/$RELEASE_FOLDER/lib/libmpkcc.a)
include_directories($MYPWD/$RELEASE_FOLDER/include/)
################################################################
"
echo "**************************************************************************************"
