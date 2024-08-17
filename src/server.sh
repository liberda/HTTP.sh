#!/usr/bin/env bash

# If $1 is set to true, enable the call trace
if [[ "$1" == true ]]; then
    set -x
fi
shopt -s extglob

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
				get_data[$name]="$value"
			fi
		done <<< "${r[url]#*\?}&"
	fi

else
	exit 1 # TODO: throw 400 here
fi

# continue with reading the headers
while read -r param; do
	[[ "$param" == $'\r' ]] && break
	r[req_headers]+="$param"
	param="${param##*( )}" # strip beginning whitespace
	param="${param%%*( )*($'\r')}" # ... and the end whitespace
	name=''
	value=''
	data=''
	unset IFS

	# TODO: think about refactoring those ifs; maybe we *don't* need to have a header "allowlist" afterall...
	# TODO: some of those options are... iffy wrt case sensitiveness

	if [[ "$param" == "content-length:"* ]]; then
		r[content_length]="${param#*:*( )}"
		declare -p param >/dev/stderr

	elif [[ "$param" == "content-type:"* ]]; then
		r[content_type]="${param#*:*( )}"
		if [[ "${r[content_type]}" == *"multipart/form-data"* ]]; then
			tmpdir=$(mktemp -d)
		fi
		if [[ "${r[content_type]}" == *"boundary="* ]]; then
			r[content_boundary]="${r[content_type]##*boundary=}"
		fi

	elif [[ "$param" == "host:"* ]]; then
		r[host]="${param#*:*( )}"
		r[host_portless]="${r[host]%%:*}"
		if [[ -f "config/$(basename -- ${r[host]})" ]]; then
			source "config/$(basename -- ${r[host]})"
		elif [[ -f "config/$(basename -- ${r[host_portless]})" ]]; then
			source "config/$(basename -- ${r[host_portless]})"
		fi

	elif [[ "$param" == "user-agent:"* ]]; then
		r[user_agent]="${param#*:*( )}"

	elif [[ "$param" == "upgrade:"* && "${param/upgrade:}" == *"websocket"* ]]; then
		r[status]=101

	elif [[ "$param" == "sec-websocket-key:"* ]]; then
		r[websocket_key]="${param#*:*( )}"

	elif [[ "$param" == "authorization: basic"* ]]; then
		login_simple "$param"

	elif [[ "$param" == "authorization: bearer"* ]]; then
		r[authorization]="${param#*:*( )[Bb]earer*( )}"

	elif [[ "$param" == "cookie: "* ]]; then
		while read -d';' i; do
			i="$(url_decode "$i")"
			name="${i%%=*}"

			if [[ "$name" ]]; then
				# get value, strip potential whitespace
				value="${i#*=}"
				value="${value##*( )}"
				value="${value%%*( )}"
				cookies[$name]="$value"
			fi
		done <<< "${param//cookie:};"

	elif [[ "$param" == "range: bytes="* ]]; then
		r[range]="${param#*=}"
	fi
done

r[url]="$(url_decode "${r[url]}")" # doing this here for.. reasons

r[uri]="$(realpath "${cfg[namespace]}/${cfg[root]}$(sed -E 's/\?(.*)$//' <<< "${r[url]}")")"
[[ -d "${r[uri]}/" ]] && pwd="${r[uri]}" || pwd=$(dirname "${r[uri]}")

if [[ $NCAT_LOCAL_PORT == '' ]]; then
	r[proto]='http'
	r[ip]="NCAT_IS_BORK"
else
	r[proto]='https'
	r[ip]="$NCAT_REMOTE_ADDR:$NCAT_REMOTE_PORT"
fi

shopt -u nocasematch

echo "$(date) - IP: ${r[ip]}, PROTO: ${r[proto]}, URL: ${r[url]}, GET_data: ${get_data[@]}, POST_data: ${post_data[@]}, POST_multipart: ${post_multipart[@]}, UA: ${r[user_agent]}" >> "${cfg[namespace]}/${cfg[log]}"

[[ -f "${cfg[namespace]}/routes.sh" ]] && source "${cfg[namespace]}/routes.sh"

if [[ ${r[status]} != 101 ]]; then
	clean_url="${r[url]%\?*}"
	for (( i=0; i<${#route[@]}; i=i+3 )); do
		if [[ "$(grep -Poh "^${route[$((i+1))]}$" <<< "$clean_url")" != "" ]] || [[ "$(grep -Poh "^${route[$((i+1))]}$" <<< "$clean_url/")" != "" ]]; then
			r[status]=212
			r[view]="${route[$((i+2))]}"
			IFS='/'
			url=(${route[$i]})
			url_=($clean_url)
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
		elif [[ "$(echo -n "${r[uri]}")" != "$(realpath "${cfg[namespace]}/${cfg[root]}")"* ]]; then
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

if [[ "${cfg[proxy]}" == true ]]; then
	r[status]=211
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

		unset IFS
		while read -r -d'&' i; do
			name="${i%%=*}"
			value="${i#*=}"
			post_data[$name]="$value"
			echo post_data[$name]="$value" >/dev/stderr

		done <<< "${data}&"
	fi
fi

if [[ ${r[status]} == 210 && ${cfg[autoindex]} == true ]]; then
	source "src/response/listing.sh"
elif [[ ${r[status]} == 211 ]]; then
	source "src/response/proxy.sh"
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
