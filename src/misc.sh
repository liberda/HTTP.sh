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
