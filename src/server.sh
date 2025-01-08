#!/usr/bin/env bash

# If $1 is set to true, enable the call trace
if [[ "$1" == true ]]; then
    set -x
fi
shopt -s extglob

source src/version.sh
source config/master.sh
source src/mime.sh
source src/misc.sh
source src/account.sh
source src/mail.sh
source src/route.sh
source src/template.sh
source src/notORM.sh # to be split off HTTP.sh at some point :^)
[[ -f "${cfg[namespace]}/config.sh" ]] && source "${cfg[namespace]}/config.sh"

declare -A r # current request / response
declare -A meta # metadata for templates
declare -A cookies # cookies!
declare -A get_data # all GET params
declare -A post_data # all POST params
declare -A params # parsed router data

r[status]=210 # Mommy always said that I was special
r[req_headers]=''
r[payload_type]=none # placeholder
post_length=0

# start reading the stream here instead of the loop below;
# this way, we can detect if the connection is even valid HTTP.
# we're reading up to 8 characters and waiting for a space.
read -d' ' -r -n8 param

shopt -s nocasematch # only for initial parse; saves us *many* sed calls

if [[ "${param,,}" =~ ^(get|post|patch|put|delete|meow) ]]; then # TODO: OPTIONS, HEAD
	r[method]="${param%% *}"
	read -r param
	[[ "${r[method],,}" != "get" ]] && r[post]=true
	r[url]="$(sed -E 's/^ *//;s/HTTP\/[0-9]+\.[0-9]+//;s/ //g;s/\/*\r//g;s/\/\/*/\//g' <<< "$param")"
	unset IFS

	if [[ "${r[url]}" == *'?'* ]]; then
		while read -d'&' i; do
			name="${i%%=*}"
			if [[ "$name" ]]; then
				value="${i#*=}"
				get_data[$name]="$(url_decode "$value")"
			fi
		done <<< "${r[url]#*\?}&"
	fi

else
	exit 1 # TODO: throw 400 here
fi

declare -A headers

IFS=$'\n'
# continue with reading the headers
while read -r param; do
	[[ "$param" == $'\r' ]] && break
	[[ "$param" != *":"* ]] && exit 1 # TODO: throw 400

    IFS=':'
    read -ra header_pair <<< "$param"
    header_key="${header_pair[0],,}" # To lowercase...
    header_key="${header_key##*( )}" # ...trim leading whitespace...
    header_key="${header_key%%*( )}" # ...and trailing whitespaces

    header_value="${header_pair[@]:1}"
    header_value="${header_value##*( )}" # Trim leading whitespace...
    headers["${header_key}"]="${header_value%%*( )*($'\r')}" # ...and trailing whitespace and \r
done
unset IFS

# TODO: remove deprecated fields below

r[content_length]="${headers["content-length"]}"
r[user_agent]="${headers["user-agent"]}"
r[websocket_key]="${headers["sec-websocket-key"]}"
r[req_headers]="$headers"
r[url]="$(url_decode "${r[url]}")" # doing this here for.. reasons
r[uri]="$(realpath "${cfg[namespace]}/${cfg[root]}/$(sed -E 's/\?(.*)$//' <<< "${r[url]}")")"
r[url_clean]="${r[url]%\?*}"
[[ -d "${r[uri]}/" ]] && pwd="${r[uri]}" || pwd=$(dirname "${r[uri]}") # dead code

if [[ -n "${headers["content-type"]}" ]]; then
    IFS=';'
    read -ra content_type <<< "${headers["content-type"]}"
    r[content_type]="${content_type[0]}"

    if [[ "${r[content_type]}" == "application/x-www-form-urlencoded" ]]; then
		r[payload_type]="urlencoded" # TODO: do we want to have a better indicator for this?
	elif [[ "${r[content_type]}" == "multipart/form-data" ]]; then
		r[payload_type]="multipart"
		tmpdir=$(mktemp -d)

        if [[ "${r[content_type]}" == "boundary="* ]]; then
            boundary="${content_type[@]:1}"
		    r[content_boundary]="${boundary##*boundary=}"
	    fi
	fi
	unset IFS
fi

if [[ -n "${headers["host"]}" ]]; then
    r[host]="${headers["host"]}"
    r[host_portless]="${headers["host"]%%:*}"

    if [[ -f "config/$(basename -- ${r[host]})" ]]; then
	    source "config/$(basename -- ${r[host]})"
	elif [[ -f "config/$(basename -- ${r[host_portless]})" ]]; then
		source "config/$(basename -- ${r[host_portless]})"
	fi
fi

if [[ "${headers["connection"]}" == "upgrade" && "${headers["upgrade"]}" == "websocket" ]]; then
    r[status]=101
fi

shopt -u nocasematch

if [[ -n "${headers["authorization"]}" ]]; then
    if [[ "${headers["authorization"],,}" == "basic"* ]]; then
        base64="${headers["authorization"]#[Bb]asic*( )}"
        login_simple "${base64##*( )}"
    elif [[ "${headers["authorization"],,}" == "bearer"* ]]; then
        bearer="${headers["authorization"]#[Bb]earer*( )}"
        r[authorization]="${bearer##*( )}"
    fi
fi

if [[ -n "${headers["cookie"]}" ]]; then
    while read -r -d';' cookie_pair; do
        cookie_pair="$(url_decode "$cookie_pair")"
		name="${cookie_pair%%=*}"
		if [[ -n "$name" ]]; then
            # get value, strip potential whitespace
            value="${cookie_pair##*=}"
            value="${value##*( )}"
            value="${value%%*( )}"
            cookies["$name"]="$value"
        fi
    done <<< "${headers["cookie"]};" # This hack is beyond me, just trust the process
fi

if [[ "${headers["range"]}" == "bytes"* ]]; then
    r[range]="${headers["range"]#*=}"
fi

if [[ ${headers["x-forwarded-for"]} ]]; then
    r[proto]='http'
    r[ip]="${headers["x-forwarded-for"]%%[, ]*}"
elif [[ -z "$NCAT_LOCAL_PORT" ]]; then
	r[proto]='http'
	r[ip]="NCAT_IS_BORK"
else
	r[proto]='https'
	r[ip]="$NCAT_REMOTE_ADDR:$NCAT_REMOTE_PORT"
fi

echo "$(date) - IP: ${r[ip]}, PROTO: ${r[proto]}, URL: ${r[url]}, GET_data: ${get_data[@]}, POST_data: ${post_data[@]}, POST_multipart: ${post_multipart[@]}, UA: ${r[user_agent]}" >> "${cfg[namespace]}/${cfg[log]}"

[[ -f "${cfg[namespace]}/routes.sh" ]] && source "${cfg[namespace]}/routes.sh"

if [[ ${r[status]} != 101 ]]; then
	for (( i=0; i<${#route[@]}; i=i+3 )); do
		if [[ "$(grep -Poh "^${route[$((i+1))]}$" <<< "${r[url_clean]}")" != "" ]] || [[ "$(grep -Poh "^${route[$((i+1))]}$" <<< "${r[url_clean]}/")" != "" ]]; then
			r[status]=212
			r[view]="${route[$((i+2))]}"
			IFS='/'
			url=(${route[$i]})
			url_=(${r[url_clean]})
			unset IFS
			for (( j=0; j<${#url[@]}; j++ )); do
				# TODO: think about the significance of this if really hard when i'm less tired
				if [[ ${url_[$j]} != '' && ${url[$j]} == ":"* ]]; then
					params[${url[$j]/:/}]="${url_[$j]}"
				fi
			done
			break
		fi
	done
	unset IFS
	if [[ ${r[status]} != 212 ]]; then
		if [[ -a "${r[uri]}" && ! -r "${r[uri]}" ]]; then
			r[status]=403
		elif [[ "${r[uri]}" != "$(realpath "${cfg[namespace]}/${cfg[root]}")"* ]]; then
			r[status]=403
		elif [[ -f "${r[uri]}" ]]; then
			r[status]=200
		elif [[ -d "${r[uri]}" ]]; then
			for name in ${cfg[index]}; do
				if [[ -f "${r[uri]}/$name" ]]; then
					r[uri]="${r[uri]}/$name"
					r[status]=200
				fi
			done
		else
			r[status]=404
		fi
	fi
fi

echo "${r[url]}" >&2

# the app config gets loaded a second time to allow for path-specific config modification
[[ -f "${cfg[namespace]}/config.sh" ]] && source "${cfg[namespace]}/config.sh"

if [[ "${cfg[auth_required]}" == true && "${r[authorized]}" != true ]]; then
	echo "Auth failed." >> ${cfg[log_misc]}
	r[status]=401
fi

if [[ "${r[post]}" == true ]] && [[ "${r[status]}" == 200 ||  "${r[status]}" == 212 ]]; then
	# This whole ordeal is here to prevent passing binary data as a variable.
	# I could have done it as an array, but this solution works, and it's
	# speedy enough so I don't care.

	if [[ $tmpdir ]]; then
		declare post_multipart
		tmpfile=$(mktemp -p $tmpdir)
		dd iflag=fullblock of=$tmpfile ibs=${r[content_length]} count=1 obs=1M

		delimeter_len=$(echo -n "${r[content_boundary]}"$'\015' | wc -c)
		boundaries_list=$(echo -ne $(grep $tmpfile -ao -e ${r[content_boundary]} --byte-offset | sed -E 's/:(.*)//g') | sed -E 's/ [0-9]+$//')

		for i in $boundaries_list; do
			tmpout=$(mktemp -p $tmpdir)
			dd iflag=fullblock if=$tmpfile ibs=$(($i+$delimeter_len)) obs=1M skip=1 | while true; do
				read -r line
				if [[ $line == $'\015' ]]; then
					cat - > $tmpout
					break
				fi
			done
			length=$(grep $tmpout --byte-offset -ae ${r[content_boundary]} | sed -E 's/:(.*)//' | head -n 1)
			outfile=$(mktemp -p $tmpdir)
			post_multipart+=($outfile)
			dd iflag=fullblock if=$tmpout ibs=$length count=1 obs=1M of=$outfile
			rm $tmpout
		done
		rm $tmpfile
	else
		read -r -N "${r[content_length]}" data

		if [[ "${r[payload_type]}" == "urlencoded" ]]; then
			unset IFS
			while read -r -d'&' i; do
				name="${i%%=*}"
				value="${i#*=}"
				post_data[$name]="$(url_decode "$value")"
				echo post_data[$name]="$value" >/dev/stderr
			done <<< "${data}&"
		else
			# this is fine?
			post_data[0]="${data%\&}"
		fi
	fi
fi

if [[ ${r[status]} == 210 && ${cfg[autoindex]} == true ]]; then
	source "src/response/listing.sh"
elif [[ ${r[status]} == 200 || ${r[status]} == 212 ]]; then
	source "src/response/200.sh"
elif [[ ${r[status]} == 401 ]]; then
	source "src/response/401.sh"
elif [[ ${r[status]} == 404 ]]; then
	source "src/response/404.sh"
elif [[ ${r[status]} == 101 ]]; then
	source "src/response/101.sh"
else
	source "src/response/403.sh"
fi
