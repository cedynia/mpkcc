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
