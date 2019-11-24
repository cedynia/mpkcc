#! /bin/bash

##sudo apt-get install dh-autoreconf

# global="$(dirname "$0")"
# . "$global/global_var.sh"
# . "$global/global_fun.sh"
# . "$global/osm_var.sh"
#
# export CC=/home/pawel/mapnik4android/android-toolchain-API23-x86_64/bin/clang
# export CXX=/home/pawel/mapnik4android/android-toolchain-API23-x86_64/bin/clang++

#now try to build osmscout-server dependencies...
####libpostal##############################################################
cd "$MYPWD"
cdIntoGitRepo "$LIBPOSTAL_GIT" "$LIBPOSTAL_FOLDER" "$LIBPOSTAL_BUILD"

./bootstrap.sh

CXXFLAGS="-fPIC" CFLAGS="-fPIC"  ./configure  \
        --prefix="$MYPWD/$OUTPUT_FOLDER/$LIBPOSTAL_BUILD" \
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
#mkdir "$SCOUT_OUT_FOLDER/libmarisa"
#git clone https://github.com/s-yata/marisa-trie.git
#cd "$MYPWD/marisa-trie"
cdIntoGitRepo "$LIBMARISA_GIT" "$LIBMARISA_FOLDER" "$LIBMARISA_BUILD"
autoreconf -i

CXXFLAGS="-fPIC" CFLAGS="-fPIC" ./configure \
      --prefix="$MYPWD/$OUTPUT_FOLDER/libmarisa" \
      CC=$CC_COMPILER \
      CXX=$CXX_COMPILER \
      --host=arm-linux  \
      --enable-static \
      --disable-shared  \
      PKG_CONFIG=""

make install -j$NPROC

###libosmscout##############################################################
cd "$MYPWD"
#mkdir "$SCOUT_OUT_FOLDER/libosmscout"
#git clone --recurse-submodule https://github.com/rinigus/libosmscout.git
#cd "$MYPWD/libosmscout/libosmscout"

cdIntoGitRepo "$LIBOSMSCOUT_GIT" "$LIBOSMSCOUT_FOLDER" "$LIBOSMSCOUT_BUILD"

patch src/osmscout/util/FileScanner.cpp < $MYPWD/patches/libosmscout_FileScanner.patch

./autogen.sh
CXXFLAGS="-fPIC" CFLAGS="-fPIC"  ./configure  \
        --prefix="$MYPWD/$OUTPUT_FOLDER/$LIBOSMSCOUT_FOLDER" \
        CC=$CC_COMPILER \
        CXX=$CXX_COMPILER \
        --host=arm-linux \
        --enable-static \
        --disable-shared \
        MARISA_LIBS="$MYPWD/$OUTPUT_FOLDER/libmarisa/lib" \
        MARISA_CFLAGS=-I"$MYPWD/$OUTPUT_FOLDER/libmarisa/include" \
        PKG_CONFIG=""

make install -j$NPROC
cp -rf $MYPWD/$BUILD_FOLDER/$LIBOSMSCOUT_FOLDER/$LIBOSMSCOUT_BUILD/include/osmscout/* $MYPWD/$OUTPUT_FOLDER/$LIBOSMSCOUT_FOLDER/include/osmscout/

###libosmscout-map##############################################################
#cd "$MYPWD"
#cd "$MYPWD/libosmscout/libosmscout-map"

cdIntoGitRepo "$LIBOSMSCOUT_GIT" "$LIBOSMSCOUT_FOLDER" "$LIBOSMSCOUTMAP_BUILD"

./autogen.sh
CFLAGS="-fPIC" CXXFLAGS="-fPIC" ./configure  \
        --prefix="$MYPWD/$OUTPUT_FOLDER/$LIBOSMSCOUT_FOLDER" \
        CC=$CC_COMPILER \
        CXX=$CXX_COMPILER \
        --host=arm-linux  \
        --enable-static \
        --disable-shared  \
        PKG_CONFIG="" \
        LIBOSMSCOUT_LIBS="$MYPWD/$OUTPUT_FOLDER/$LIBOSMSCOUT_FOLDER/lib"  \
        LIBOSMSCOUT_CFLAGS=-I"$MYPWD/$OUTPUT_FOLDER/$LIBOSMSCOUT_FOLDER/include"

make install -j$NPROC

###kyoto########################################################################
cd "$MYPWD"
#mkdir "$SCOUT_OUT_FOLDER/kyoto"
#wget https://fallabs.com/kyotocabinet/pkg/kyotocabinet-1.2.77.tar.gz
#tar -xf kyotocabinet-1.2.77.tar.gz
#cd "$MYPWD/kyotocabinet-1.2.77"

cdIntoSrc "$LIBKYOTOCABINET_FOLDER"

patch kcthread.cc < $MYPWD/patches/kyoto_kcthread.patch

CXXFLAGS="-D_MYGCCATOMIC -fPIC" ./configure   \
        --disable-atomic \
        --disable-zlib  \
        --prefix="$MYPWD/$OUTPUT_FOLDER/$LIBKYOTOCABINET_OUTPUT" \
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



cdIntoGitRepo "$LIBOPENSSL_GIT" "$LIBOPENSSL_FOLDER"
##for version compability 1.1.1d see configure qt
git checkout 433f924a9dc6df5b35d5e7e76453c200b84
echo "sciezka:...." $PWD
cd $MYPWD/$OUTPUT_FOLDER/$LIBOPENSSL_FOLDER
sed -i 's,ANDROID_NDK_HOME=.*,ANDROID_NDK_HOME='"$NDK_ROOT"',g' ./build_ssl.sh
./build_ssl.sh
cp -rf $MYPWD/$BUILD_FOLDER/$LIBOPENSSL_FOLDER $MYPWD/$OUTPUT_FOLDER/

##download and buid qt src
cdIntoSrc $LIBQT_FOLDER
./configure -confirm-license -xplatform android-clang --disable-rpath -nomake tests -nomake examples -android-arch $ARCH -android-ndk $NDK_ROOT -android-sdk $SDK_ROOT -android-ndk-host linux-x86_64 -android-toolchain-version 4.9 -no-warnings-are-errors -android-ndk-platform android-$API_VERSION -skip qttools -skip qttranslations -skip qtwebengine -skip qtserialport -skip qtserialbus -I$MYPWD/$OUTPUT_FOLDER/$LIBOPENSSL_FOLDER/openssl-1.1.1d/include/ -openssl -prefix $LIBQT_OUTPUT -opensource
make -j$NPROC
make install
