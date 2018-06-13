#! /bin/bash

NDK_ROOT=
API_VERSION=
MYPWD=$(pwd)
TOOLCHAIN_FOLDER=
TOOLCHAIN_PATH=
CC_COMPILER=
CXX_COMPILER=
BUILD=arm-linux-androideabi

BOOST_FOLDER=boost_1_64_0.tar.gz
BOOST_VERSION=1.64.0
BOOST_OUTPUT=boost

ZLIB_FOLDER=zlib-1.2.11.tar.xz
ZLIB_OUTPUT=zlib

LIBXML_FOLDER=libxml2-2.9.0.tar.gz
LIBXML_OUTPUT=libxml2

LIBTIFF_FOLDER=tiff-4.0.9.tar.gz
LIBTIFF_OUTPUT=libtiff

LIBJPEG_FOLDER=jpegsrc.v9c.tar.gz
LIBJPEG_OUTPUT=libjpeg

#hardcoded ftp link
LIBPNG_FOLDER=libpng-1.2.59.tar.gz
LIBPNG_OUTPUT=libpng

LIBPROJ_FOLDER=proj-4.5.0.tar.gz
LIBPROJ_OUTPUT=libproj

LIBFREETYPE_FOLDER=freetype-2.9.tar.gz
LIBFREETYPE_OUTPUT=libfreetype

LIBHARFBUZZ_FOLDER=harfbuzz-1.8.0.tar.bz2
LIBHARFBUZZ_OUTPUT=libharfbuzz

LIBICU_FOLDER=icu4c-50_1_2-src.tgz
LIBICU_VERSION=50.1.2
LIBICU_OUTPUT=libicu

MAPNIK_VERSION=3.0.20

pattern_match ()
{
    echo "$2" | grep -q -E -e "$1"
}

function validateLink(){

	# Is this HTTP, HTTPS?
	if pattern_match "^(http|https):.*" "$1"; then
		if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
			true;
		else
			false;
		fi
	#Is this FTP?
	elif pattern_match "^(ftp):/*" "$1"; then
		if [[ `wget -S --spider $1  2>&1 | grep 'exists'` ]]; then
			true;
		else
			false;
		fi
	else
		false;
	fi

}

function cdIntoFold(){

	#local foldName=$(echo $1 | sed 's/\(.*\)\.\(.*\)\.\(.*\)/\1/g')
	local foldName=$(echo $1 | awk -F. '{ print $1 }')
	echo $foldName

	if [ -d "$MYPWD/build/$foldName" ];then
		cd "$MYPWD/build/$foldName"
	else
		mkdir -p "$MYPWD/build/$foldName"
		tar -xvf "$MYPWD/.arch/$1" --strip-components 1 -C "$MYPWD/build/$foldName"
		cd "$MYPWD/build/$foldName"
	fi
}

# echo "downloading..."
#
# for arch in ${!archArray[@]};
# do
# 	if [ ${archArray[$arch]} = false ];then
# 		wget -P .arch ${linksArray[$arch]}
# 	fi
# done


#uncoment the line if you want to try to build the official master
MAPNIK_MASTER=https://github.com/mapnik/mapnik.git
#...or the snapshot master from VI 2018
#MAPNIK_MASTER=https://gitlab.com/czysty/mapnik_snapshot_master.git

################################################################################

declare -A archArray

archArray=(
						["$BOOST_FOLDER"]=false
						["$ZLIB_FOLDER"]=false
						["$LIBXML_FOLDER"]=false
						["$LIBTIFF_FOLDER"]=false
						["$LIBJPEG_FOLDER"]=false
						["$LIBPNG_FOLDER"]=false
						["$LIBPROJ_FOLDER"]=false
						["$LIBFREETYPE_FOLDER"]=false
						["$LIBHARFBUZZ_FOLDER"]=false
						["$LIBICU_FOLDER"]=false
	  			)

declare -A linksArray

linksArray=(
						["$BOOST_FOLDER"]="https://dl.bintray.com/boostorg/release/$BOOST_VERSION/source/$BOOST_FOLDER"
						["$ZLIB_FOLDER"]="https://zlib.net/$ZLIB_FOLDER"
						["$LIBXML_FOLDER"]="ftp://xmlsoft.org/libxml2/$LIBXML_FOLDER"
						["$LIBTIFF_FOLDER"]="https://download.osgeo.org/libtiff/$LIBTIFF_FOLDER"
						["$LIBJPEG_FOLDER"]="http://www.ijg.org/files/$LIBJPEG_FOLDER"
						["$LIBPNG_FOLDER"]="http://ftp-osl.osuosl.org/pub/libpng/src/libpng12/$LIBPNG_FOLDER"
						["$LIBPROJ_FOLDER"]="https://download.osgeo.org/proj/$LIBPROJ_FOLDER"
						["$LIBFREETYPE_FOLDER"]="https://download.savannah.gnu.org/releases/freetype/$LIBFREETYPE_FOLDER"
						["$LIBHARFBUZZ_FOLDER"]="https://www.freedesktop.org/software/harfbuzz/release/$LIBHARFBUZZ_FOLDER"
						["$LIBICU_FOLDER"]="http://download.icu-project.org/files/icu4c/$LIBICU_VERSION/$LIBICU_FOLDER"
					)

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
	if [ ${archArray[$arch]} = false ] && ! validateLink ${linksArray[$arch]} ;then echo "the download link for $arch is not responding, please download $arch manually to .arch folder"; exit 1;fi
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

if [ ${archArray[$BOOST_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$BOOST_FOLDER]}
fi

cdIntoFold "$BOOST_FOLDER"

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

if [ ${archArray[$ZLIB_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$ZLIB_FOLDER]}
fi

cdIntoFold "$ZLIB_FOLDER"

./configure \
	--prefix=$MYPWD/$ZLIB_OUTPUT \
	--static

make install -j2

###########LIBXML
cd $MYPWD

if [ ${archArray[$LIBXML_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$LIBXML_FOLDER]}
fi

# #make will fail because android < 28 doesnt have glob and globfree functions
# #but they are required only for tests, so we have to manually copy static libs from .lib folder
# #to our libxml2 folder
mkdir $MYPWD/$LIBXML_OUTPUT/
mkdir $MYPWD/$LIBXML_OUTPUT/lib

cdIntoFold "$LIBXML_FOLDER"

./configure \
		--host=$BUILD \
		--prefix=$MYPWD/$LIBXML_OUTPUT \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

cp .libs/libxml2.a $MYPWD/$LIBXML_OUTPUT/lib/

make install -j2

############LIBTIFF
cd $MYPWD

if [ ${archArray[$LIBTIFF_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$LIBTIFF_FOLDER]}
fi

cdIntoFold "$LIBTIFF_FOLDER"

./configure \
		--host=arm-linux \
		--enable-static \
		--prefix=$MYPWD/$LIBTIFF_OUTPUT \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j2

###########LIBJPEG
cd $MYPWD

if [ ${archArray[$LIBJPEG_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$LIBJPEG_FOLDER]}
fi

cdIntoFold "$LIBJPEG_FOLDER"

./configure \
		--host=arm-linux \
		--enable-static \
		--prefix=$MYPWD/$LIBJPEG_OUTPUT \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j2

############LIBPNG
cd $MYPWD

if [ ${archArray[$LIBPNG_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$LIBPNG_FOLDER]}
fi

cdIntoFold "$LIBPNG_FOLDER"

./configure \
		--enable-static \
		--prefix=$MYPWD/$LIBPNG_OUTPUT \
		--host=arm-linux-androideabi \
		CC=$CC_COMPILER \
		CXX=$CXX_COMPILER

make install -j2

#############LIBPROJ
cd $MYPWD

if [ ${archArray[$LIBPROJ_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$LIBPROJ_FOLDER]}
fi

cdIntoFold "$LIBPROJ_FOLDER"

./configure \
			--enable-static \
			--prefix=$MYPWD/$LIBPROJ_OUTPUT \
			--host=arm-linux \
			CC=$CC_COMPILER \
			CXX=$CXX_COMPILER

make install -j2

#############LIBFREETYPE
cd $MYPWD

if [ ${archArray[$LIBFREETYPE_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$LIBFREETYPE_FOLDER]}
fi

cdIntoFold "$LIBFREETYPE_FOLDER"

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

if [ ${archArray[$LIBHARFBUZZ_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$LIBHARFBUZZ_FOLDER]}
fi

cdIntoFold "$LIBHARFBUZZ_FOLDER"

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

if [ ${archArray[$LIBICU_FOLDER]} = false ];then
	wget -P .arch ${linksArray[$LIBICU_FOLDER]}
fi

cdIntoFold "$LIBICU_FOLDER"

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
