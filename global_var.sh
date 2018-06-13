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
#uncoment the line if you want to try to build the official master
MAPNIK_MASTER=https://github.com/mapnik/mapnik.git
#...or the snapshot master from VI 2018
#MAPNIK_MASTER=https://gitlab.com/czysty/mapnik_snapshot_master.git
