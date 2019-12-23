#! /bin/bash

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

function checkArchs(){
  for A in ${!archArray[@]};
  do
  	if [ -f $ARCHIVE_FOLDER/$A ];then archArray[$A]=true; fi
  done

  for arch in ${!archArray[@]};
  do
  	if [ ${archArray[$arch]} = false ] && ! validateLink ${linksArray[$arch]} ;then
  		echo "the download link for $arch is not responding, please download $arch manually to $ARCHIVE_FOLDER folder";
  		exit 1;
  	fi
  done

}

function cdIntoGitRepo(){

  	wget -O /dev/null $1
    if [ $? -ne 0 ];then
      echo "Can't download $1, please download $1 manually to .arch folder"
      exit 1;
    fi

    git clone --recurse-submodule $1 "$MYPWD/$BUILD_FOLDER/$2"
    cd "$MYPWD/$BUILD_FOLDER/$2/$3"

}

function cdIntoSrc(){
  cd "$MYPWD"

  #FIXME:no connection handling
  echo "sciezka ktora sciagam: ${linksArray[$1]}"
  if [ ${archArray[$1]} = false ];then
  	wget -O $ARCHIVE_FOLDER/$1 ${linksArray[$1]}
    if [ $? -ne 0 ];then
      echo "Can't download $1, please download $1 manually to .arch folder"
      exit 1;
    fi
  fi

  #local foldName=$(echo $1 | sed 's/\(.*\)\.\(.*\)\.\(.*\)/\1/g')
  local foldName=$(echo $1 | awk -F. '{ print $1 }')
  echo $foldName

  if [ -d "$MYPWD/$BUILD_FOLDER/$foldName" ];then
  	cd "$MYPWD/$BUILD_FOLDER/$foldName"
  else
  	mkdir -p "$MYPWD/$BUILD_FOLDER/$foldName"
  	tar -xf "$MYPWD/$ARCHIVE_FOLDER/$1" --strip-components 1 -C "$MYPWD/$BUILD_FOLDER/$foldName"
  	cd "$MYPWD/$BUILD_FOLDER/$foldName"
  fi
}

function checkCompResult(){

  if [ ! -d "$MYPWD/$OUTPUT_FOLDER/$1" ];then
    echo "Can't compile $1, check the compiler output."
    exit 1;
  fi

}

function checkFold(){

  if [ ! -d "$MYPWD/$1" ];then
      mkdir $MYPWD/$1
  else
      if [ $1 != $ARCHIVE_FOLDER ];then
      rm -rf $MYPWD/$1
      mkdir $MYPWD/$1
    fi
  fi

}

function store_vars(){

  NDK_VER=$(dialog --backtitle "Step 1" \
  --title "SELECT NDK VERSION TO DOWNLOAD..." --clear "$@" \
  --stdout \
        --radiolist "" 10 61 5 \
        "r19c" "" on \
        "r18b" "" off \
        "r20b" "" off )

  ARCH=$(dialog --backtitle "Step 2" \
  --title "CHOOSE ARCHITECTURE..." --clear "$@" \
  --stdout \
        --radiolist "" 10 61 5 \
        "arm" "" on \
        "arm64" "" off \
        "x86_64" "" off \
  "x86" "" off )

  API_VERSION=$(dialog --backtitle "Step 3" \
  --title "CHOOSE MIN. API VERSION..." --clear "$@" \
  --stdout \
        --radiolist "" 10 61 5 \
        "23" "" on )

  exec 3>&1
  SDK_ROOT="$(dialog --title "Please choose a folder" \
  	  "$@" \
  	  --dselect $HOME/ \
  	  10 48 28 2>&1 1>&3)"
  exec 3>&-


}

function make_toolchain(){

  case "$NDK_VER" in
  	"r19c") echo "wybrano 19";
  	if [ ! -f "./$ARCHIVE_FOLDER/android-ndk-r19c.zip" ];then
  	  wget "$ndk_r19c" -O "./$ARCHIVE_FOLDER/android-ndk-r19c.zip";
  	fi;;
  	"r18b") echo "wybrano 18";
  	if [ ! -f "./$ARCHIVE_FOLDER/android-ndk-r18b.zip" ];then
  	  wget "$ndk_r18b" -O "./$ARCHIVE_FOLDER/android-ndk-r18b.zip";
  	fi;;
    "r20b") echo "wybrano 20";
    if [ ! -f "./$ARCHIVE_FOLDER/android-ndk-r20b.zip" ];then
      wget "$ndk_r20b" -O "./$ARCHIVE_FOLDER/android-ndk-r20b.zip";
    fi;;
  esac

  if [ $? -ne 0 ];then
    echo "cant download ndk toolchain!"
    exit 1;
  fi
  echo "extracting ndk toolchain";


  unzip -qo $MYPWD/$ARCHIVE_FOLDER/android-ndk-$NDK_VER.zip \
    -d $MYPWD/$BUILD_FOLDER/ndk

  $MYPWD/$BUILD_FOLDER/ndk/android-ndk-$NDK_VER/build/tools/make_standalone_toolchain.py \
  --arch=$ARCH_NDK \
  --api=$API_VERSION \
  --stl=libc++ \
  --force \
  --verbose \
  --install-dir=$MYPWD/$TOOLCHAIN_FOLDER

  NDK_ROOT=$MYPWD/$BUILD_FOLDER/ndk/android-ndk-$NDK_VER/


}
