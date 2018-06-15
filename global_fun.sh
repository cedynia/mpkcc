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

  if [ ${archArray[$1]} = false ];then
  	wget -P $ARCHIVE_FOLDER ${linksArray[$1]}
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
