printf "HTTP/1.0 200 OK
${cfg[extra_headers]}\r\n"
get_mime ${r[uri]}
[[ $content_type != '' ]] && printf "content-type: $content_type\r\n"

if [[ ${r[uri]} =~ \.${cfg[extension]}$ ]]; then
	temp=$(mktemp)
	source "${r[uri]}" > $temp
	[[ ${r[headers]} != '' ]] && printf "${r[headers]}\r\n\r\n" || printf "\r\n"
	cat $temp
	rm $temp
else
	printf "\r\n"
	cat "${r[uri]}"
fi

