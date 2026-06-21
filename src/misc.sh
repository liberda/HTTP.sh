#!/usr/bin/env bash
# misc.sh - miscellaneous functions

# set_cookie(cookie_name, cookie_content)
function set_cookie() {
	r[headers]+="Set-Cookie: $1=$2; Path=${cfg[cookie_path]}\r\n"
	cookies["$1"]="$2"
}

# set_cookie_permanent(cookie_name, cookie_content)
function set_cookie_permanent() {
	r[headers]+="Set-Cookie: $1=$2; Expires=Mon, 26 Jul 2100 22:45:00 GMT; Path=${cfg[cookie_path]}\r\n"
	cookies["$1"]="$2"
}

# remove_cookie(cookie_name)
function remove_cookie() {
	r[headers]+="Set-Cookie: $1=; Expires=Sat, 02 Apr 2005 20:37:00 GMT\r\n"
	unset cookies["$1"]
}

# header(header, header...)
function header() {
	local i
	for i in "$@"; do
		r[headers]+="$i\r\n"
	done
}

# get_dump()
function get_dump() {
	local i
	for i in "${!get_data[@]}"; do
		echo "${i}=${get_data[$i]}"
	done
}

# post_dump()
function post_dump() {
	local i
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
	echo -n "$1" | xxd -p | tr -d '\n' | sed 's/../%&/g'
}

# url_decode(string)
function url_decode() {
	# we should probably fail on invalid data here,
	# but this function is kinda sorta infallible right now

	local t=$'\01'
	local a="${1//$t}" # strip all of our control chrs for safety
	a="${a//+/ }" # handle whitespace
	a="${a//%[A-Fa-f0-9][A-Fa-f0-9]/$t&}" # match '%xx', prepend with token
	echo -ne "${a//$t%/\\x}" # replace the above with '\\x' and evaluate
}

# bogus function!
# this is here to prevent "command not found" errors in debug mode
function worker_add() {
	:
}

# internal function
# common GET/POST application/x-www-form-urlencoded parser
#
# _param_parse(input, destination_ref)
_param_parse() {
	[[ ! "$1" || ! "$2" ]] && return 1
	local -n ref="$2"

	local i name value
	
	while read -d'&' i; do
		name="${i%%=*}"
		if [[ "$name" ]]; then
			value="${i#*=}"
			if [[ "${ref["$name"]}" ]]; then # array mode
				if [[ ! "${http_array_refs["$name"]}" ]]; then
					http_array_refs["$name"]=_param_$RANDOM
					local -n arr="${http_array_refs["$name"]}"

					arr=("${ref["$name"]}")
					ref["$name"]="[array]"
				else
					local -n arr="${http_array_refs["$name"]}"
				fi
				
				arr+=("$(url_decode "$value")")
			else
				ref["$name"]="$(url_decode "$value")"
			fi
		fi
	done <<< "$1"

	ref="$(url_decode "${1%%&}")" # fallback for accessing raw data
}


# Safely receive a reference to a HTTP urlencoded array
#
# http_array(name, out_ref)
http_array() {
	[[ ! "$1" || ! "$2" ]] && return 1
	if [[ ! "${http_array_refs[$1]}" ]]; then
		declare -ga $2
		local -n ref=$2

		if [[ "${post_data[$1]}" ]]; then
			ref=("${post_data[$1]}")
		elif [[ "${get_data[$1]}" ]]; then
			ref=("${get_data[$1]}")
		else
			return 1
		fi
	else
		declare -gn $2=${http_array_refs[$1]}
	fi
}
