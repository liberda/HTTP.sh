#!/usr/bin/env bash
# misc.sh - miscellaneous functions

# set_cookie(cookie_name, cookie_content)
function set_cookie() {
	r[headers]+="Set-Cookie: $1=$2; Path=${cfg[cookie_path]}\r\n"
}

# set_cookie_permanent(cookie_name, cookie_content)
function set_cookie_permanent() {
	r[headers]+="Set-Cookie: $1=$2; Expires=Mon, 26 Jul 2100 22:45:00 GMT; Path=${cfg[cookie_path]}\r\n"
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
	if [[ "$1" == "" ]]; then
		sed 's/\&/\&amp;/g;s/</\&#60;/g;s/>/\&#62;/g;s/%/\&#37;/g;s/\//\&#47;/g;s/\\/\&#92;/g;s/'"'"'/\&#39;/g;s/"/\&#34;/g;s/`/\&#96;/g;s/?/\&#63;/g;'
	else
		sed 's/\&/\&amp;/g;s/</\&#60;/g;s/>/\&#62;/g;s/%/\&#37;/g;s/\//\&#47;/g;s/\\/\&#92;/g;s/'"'"'/\&#39;/g;s/"/\&#34;/g;s/`/\&#96;/g;s/?/\&#63;/g;' <<< "$1"
	fi
}

# url_encode(string)
function url_encode() {
	echo -n "$1" | xxd -p | tr -d '\n' | sed -E 's/.{2}/%&/g'
}

# url_decode(string)
function url_decode() {
	# we should probably fail on invalid data here,
	# but this function is kinda sorta infallible right now

	local t=$'\01'
	local a="${1//$t}" # strip all of our control chrs for safety
	a="${1//+/ }" # handle whitespace
	a="${a//%[A-Fa-f0-9][A-Fa-f0-9]/$t&}" # match '%xx', prepend with token
	echo -ne "${a//$t%/\\x}" # replace the above with '\\x' and evaluate
}

# bogus function!
# this is here to prevent "command not found" errors in debug mode
function worker_add() {
	:
}
