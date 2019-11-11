#! /bin/bash

##sudo apt-get install dh-autoreconf

#firstly compile the mapnik library with their dependencies
#global_var="$(dirname "$0")"
#. "$global_var/script_dev.sh"

global_var="$(dirname "$0")"
. "$global_var/osmscout-server_var.sh"


export CC_COMPILER="/home/pawel/mapnik4android/android-toolchain-API23-x86/bin/clang"
export CXX_COMPILER="/home/pawel/mapnik4android/android-toolchain-API23-x86/bin/clang++"

mkdir $SCOUT_OUT_FOLDER

#now try to build osmscout-server dependencies...


####libpostal##############################################################
cd "$MYPWD"
mkdir "$SCOUT_OUT_FOLDER/libpostal"

git clone --recurse-submodule https://github.com/rinigus/pkg-libpostal.git
cd "$MYPWD/pkg-libpostal/libpostal"
./bootstrap.sh

CXXFLAGS="-fPIC" CFLAGS="-fPIC"  ./configure  \
        --prefix="$SCOUT_OUT_FOLDER/libpostal" \
        CC=$CC_COMPILER \
        CXX=$CXX_COMPILER \
        --host=arm-linux \
        --enable-static \
        --disable-shared \
        PKG_CONFIG="" \
        --disable-sse2 \
        --datadir=/usr/local/libpostal/data \
        --disable-data-download

make install -j$NPROC

###marisa-trie#################################################################
cd "$MYPWD"
mkdir "$SCOUT_OUT_FOLDER/libmarisa"

git clone https://github.com/s-yata/marisa-trie.git
cd "$MYPWD/marisa-trie"
autoreconf -i

CXXFLAGS="-fPIC" CFLAGS="-fPIC" ./configure \
      --prefix="$SCOUT_OUT_FOLDER/libmarisa" \
      CC=$CC_COMPILER \
      CXX=$CXX_COMPILER \
      --host=arm-linux  \
      --enable-static \
      --disable-shared  \
      PKG_CONFIG=""

make install -j$NPROC

###libosmscout##############################################################
cd "$MYPWD"
mkdir "$SCOUT_OUT_FOLDER/libosmscout"

git clone --recurse-submodule https://github.com/rinigus/libosmscout.git
cd "$MYPWD/libosmscout/libosmscout"

patch src/osmscout/util/FileScanner.cpp < $MYPWD/patches/libosmscout_FileScanner.patch

./autogen.sh
CXXFLAGS="-fPIC" CFLAGS="-fPIC"  ./configure  \
        --prefix="$SCOUT_OUT_FOLDER/libosmscout" \
        CC=$CC_COMPILER \
        CXX=$CXX_COMPILER \
        --host=arm-linux \
        --enable-static \
        --disable-shared \
        MARISA_LIBS="$SCOUT_OUT_FOLDER/libmarisa/lib" \
        MARISA_CFLAGS=-I"$SCOUT_OUT_FOLDER/libmarisa/include" \
        PKG_CONFIG=""

make install -j$NPROC
cp -rf $MYPWD/libosmscout/libosmscout/include/osmscout/* $SCOUT_OUT_FOLDER/libosmscout/include/osmscout/

###libosmscout-map##############################################################
cd "$MYPWD"
cd "$MYPWD/libosmscout/libosmscout-map"

./autogen.sh
CFLAGS="-fPIC" CXXFLAGS="-fPIC"   ./configure  \
        --prefix="$SCOUT_OUT_FOLDER/libosmscout" \
        CC=$CC_COMPILER \
        CXX=$CXX_COMPILER \
        --host=arm-linux  \
        --enable-static \
        --disable-shared  \
        PKG_CONFIG="" \
        LIBOSMSCOUT_LIBS="$SCOUT_OUT_FOLDER/libosmscout/lib"  \
        LIBOSMSCOUT_CFLAGS=-I"$MYPWD/libosmscout/libosmscout/include"

make install -j$NPROC

###kyoto########################################################################
cd "$MYPWD"
mkdir "$SCOUT_OUT_FOLDER/kyoto"

wget https://fallabs.com/kyotocabinet/pkg/kyotocabinet-1.2.77.tar.gz

tar -xf kyotocabinet-1.2.77.tar.gz
cd "$MYPWD/kyotocabinet-1.2.77"

patch kcthread.cc < $MYPWD/patches/kyoto_kcthread.patch

CXXFLAGS="-D_MYGCCATOMIC -fPIC" ./configure   \
        --disable-atomic \
        --prefix="$SCOUT_OUT_FOLDER/kyoto" \
        CC=$CC_COMPILER \
        CXX=$CXX_COMPILER \
        --host=arm-linux \
        --enable-static \
        --disable-shared  \
        PKG_CONFIG=""  \
        ac_cv_c_bigendian=yes \
        LIBS=-ldl

sed -i 's/-D_FILE_OFFSET_BITS=64//g' Makefile

make -j$NPROC
make install
