#!/bin/bash
# misc.sh - miscellaneous functions

# set_cookie(cookie_name, cookie_content)
function set_cookie() {
	r[headers]+="Set-Cookie: $1=$2\r\n"
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
