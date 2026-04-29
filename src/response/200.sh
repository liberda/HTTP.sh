# TODO: move parts of this into server.sh, or rename the file appropriately

# __headers(end)
# Sets the header and terminates the header block if end is NOT set to false
function __headers() {
	if [[ "${cfg[unbuffered]}" != true ]]; then
		if [[ "${r[headers]}" == *'Location'* ]]; then # override for redirects
			echo -ne "HTTP/1.0 302 aaaaa\r\n"	
		elif [[ "${r[status]}" == '200' || "${r[status]}" == '212' ]]; then # normal or router, should just return 200
			echo -ne "HTTP/1.0 200 OK\r\n"
		else # changed by the user in the meantime :)
			[[ ! "${r[status]}" ]] && r[status]=500 # ... if they left it blank
			echo -ne "HTTP/1.0 ${r[status]} meow\r\n"
		fi
		[[ "${r[headers]}" != '' ]] && echo -ne "${r[headers]}"
		echo -ne "${cfg[extra_headers]}\r\n"
	else
		echo "uh oh - we're running unbuffered" > /dev/stderr
	fi
	
	if [[ ${r[status]} == 200 ]]; then
		get_mime "${r[uri]}"
		[[ "$mimetype" != '' ]] && echo -ne "content-type: $mimetype\r\n"
	fi

    [[ "$1" != false ]] && echo -ne "\r\n"
}

if [[ ${r[status]} == 212 ]]; then
	if [[ "${cfg[unbuffered]}" == true ]]; then
		source "${r[view]}"
	else
		# open a dummy fd to keep our data in
		exec 253<> >(tail -c 2047m)
		source "${r[view]}" >&253
		__headers
		exec 253<&- # flush the data out
		wait # wait for the transfer to finish

	fi

elif [[ "${r[uri]}" =~ \.${cfg[extension]}$ ]]; then
	exec 253<> >(tail -c 2047m)
	source "${r[uri]}" >&253
	__headers
	exec 253<&-
	wait

else
	__headers
	if [[ "$mimetype" == "text/"* && "${cfg[encoding]}" != '' ]]; then
		iconv "${r[uri]}" -f UTF-8 -t "${cfg[encoding]}"
	else
		cat "${r[uri]}"
	fi
	
fi
