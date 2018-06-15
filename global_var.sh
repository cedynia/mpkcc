#! /bin/bash

NDK_ROOT=
API_VERSION=
MYPWD=$(pwd)
TOOLCHAIN_FOLDER=
TOOLCHAIN_PATH=
CC_COMPILER=
CXX_COMPILER=
BUILD=arm-linux-androideabi

BUILD_FOLDER='build'
OUTPUT_FOLDER='output'
ARCHIVE_FOLDER='.arch'

MAPNIK_OUTPUT=mapnik-lib

BOOST_FOLDER=boost_1_64_0.tar.gz
BOOST_VERSION=1.64.0
BOOST_OUTPUT=boost

ZLIB_FOLDER=zlib-1.2.11.tar.xz
ZLIB_OUTPUT=zlib

LIBXML_FOLDER=libxml2-2.9.8.tar.gz
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
#uncoment the line if you want to try to build the official master
MAPNIK_MASTER=https://github.com/mapnik/mapnik.git
#...or the snapshot master from VI 2018
#MAPNIK_MASTER=https://gitlab.com/czysty/mapnik_snapshot_master.git

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
