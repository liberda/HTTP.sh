function __headers() {
	if [[ "${cfg[unbuffered]}" != true ]]; then
		if [[ "${r[headers]}" == *'Location'* ]]; then
			printf "HTTP/1.0 302 aaaaa\r\n"	
		else
			printf "HTTP/1.0 200 OK\r\n"
		fi
		[[ "${r[headers]}" != '' ]] && printf "${r[headers]}"
		printf "${cfg[extra_headers]}\r\n"
	else
		echo "uh oh - we're running unbuffered" > /dev/stderr
	fi
	
	if [[ ${r[status]} == 200 ]]; then
		get_mime "${r[uri]}"
		[[ "$mimetype" != '' ]] && printf "content-type: $mimetype\r\n"
	fi
	printf "\r\n"
}

if [[ ${r[status]} == 212 ]]; then
	if [[ "${cfg[unbuffered]}" == true ]]; then
		source "${r[view]}"
	else
		temp=$(mktemp)
		source "${r[view]}" > $temp
		__headers
		cat $temp
		rm $temp
	fi
	
elif [[ "${cfg[php_enabled]}" == true && "${r[uri]}" =~ ".php" ]]; then
	temp=$(mktemp)
	php "${r[uri]}" "$(get_dump)" "$(post_dump)" > $temp
	__headers
	cat $temp
	rm $temp

elif [[ "${cfg[python_enabled]}" == true && "${r[uri]}" =~ ".py" ]]; then
	temp=$(mktemp)
	python "${r[uri]}" "$(get_dump)" "$(post_dump)" > $temp
	__headers
	cat $temp
	rm $temp

elif [[ "${r[uri]}" =~ \.${cfg[extension]}$ ]]; then
	temp=$(mktemp)
	source "${r[uri]}" > $temp
	__headers
	if [[ "${cfg[encoding]}" != '' ]]; then
		iconv $temp -f UTF-8 -t "${cfg[encoding]}"
	else
		cat $temp
	fi
	rm $temp

else
	__headers
	if [[ "$mimetype" == "text/"* && "${cfg[encoding]}" != '' ]]; then
		iconv "${r[uri]}" -f UTF-8 -t "${cfg[encoding]}"
	else
		cat "${r[uri]}"
	fi
	
fi
