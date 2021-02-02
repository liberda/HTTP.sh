printf "HTTP/1.0 200 OK
${cfg[extra_headers]}\r\n"
get_mime "${r[uri]}"
[[ "$mimetype" != '' ]] && printf "content-type: $mimetype\r\n"

if [[ ${cfg[php_enabled]} == true && ${r[uri]} =~ ".php" ]]; then
	temp=$(mktemp)
	php "${r[uri]}" "$(get_dump)" "$(post_dump)" > $temp
	[[ ${r[headers]} != '' ]] && printf "${r[headers]}\r\n\r\n" || printf "\r\n"
	cat $temp
	rm $temp

elif [[ ${cfg[python_enabled]} == true && ${r[uri]} =~ ".py" ]]; then
	temp=$(mktemp)
	python "${r[uri]}" "$(get_dump)" "$(post_dump)" > $temp
	[[ ${r[headers]} != '' ]] && printf "${r[headers]}\r\n\r\n" || printf "\r\n"
	cat $temp
	rm $temp

elif [[ ${r[uri]} =~ \.${cfg[extension]}$ ]]; then
	temp=$(mktemp)
	source "${r[uri]}" > $temp
	[[ "${r[headers]}" != '' ]] && printf "${r[headers]}\r\n\r\n" || printf "\r\n"
	if [[ "${cfg[encoding]}" != '' ]]; then
		iconv $temp -f UTF-8 -t "${cfg[encoding]}"
	else
		cat $temp
	fi
	rm $temp

else
	printf "\r\n"
	if [[ "$mimetype" == "text/"* && "${cfg[encoding]}" != '' ]]; then
		iconv "${r[uri]}" -f UTF-8 -t "${cfg[encoding]}"
	else
		cat "${r[uri]}"
	fi
	
fi
