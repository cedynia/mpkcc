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

function cdIntoSrc(){

  #FIXME:no connection handling
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
		tar -xvf "$MYPWD/$ARCHIVE_FOLDER/$1" --strip-components 1 -C "$MYPWD/$BUILD_FOLDER/$foldName"
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
    echo "$MYPWD/$1 doesnt exist!"
    mkdir $MYPWD/$1
  else
    echo "$MYPWD/$1 exist"
    if [ $1 != $ARCHIVE_FOLDER ];then
      rm -rf $MYPWD/$1
    fi
  fi

}
