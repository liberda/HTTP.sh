#!/bin/bash
# misc.sh - miscellaneous functions

# set_cookie(cookie_name, cookie_content)
function set_cookie() {
	r[headers]+="Set-Cookie: $1=$2\r\n"
}

# set_cookie_permanent(cookie_name, cookie_content)
function set_cookie_permanent() {
	r[headers]+="Set-Cookie: $1=$2; Expires=Mon, 26 Jul 2100 22:45:00 GMT\r\n"
}

# remove_cookie(cookie_name)
function remove_cookie() {
	r[headers]+="Set-Cookie: $1=; Expires=Sat, 02 Apr 2005 20:37:00 GMT\r\n"
}

# header(header, header...)
function header() {
	for i in "$@"; do
		r[headers]+="$i\r\n"
	done
}

# get_dump()
function get_dump() {
	for i in "${!get_data[@]}"; do
		echo "${i}=${get_data[$i]}"
	done
}

# post_dump()
function post_dump() {
	for i in "${!post_data[@]}"; do
			echo "${i}=${post_data[$i]}"
	done
}

# html_encode(string)
function html_encode() {
	sed 's/\&/\&amp;/g;s/</\&#60;/g;s/>/\&#62;/g;s/%/\&#37;/g;s/\//\&#47;/g;s/\\/\&#92;/g;s/'"'"'/\&#39;/g;s/"/\&#34;/g;s/`/\&#96;/g;s/?/\&#63;/g;' <<< "$1"
}

# url_encode(string)
function url_encode() {
	xxd -ps -u <<< "$1" | tr -d '\n' | sed -E 's/.{2}/%&/g'
}

# url_decode(string)
function url_decode() {
	echo -ne "$(sed -E 's/%[0-1][0-9a-f]//g;s/%/\\x/g' <<< "$1")"
}
