#!/usr/bin/env bash

# If $1 is set to true, enable the call trace
if [[ "$1" == true ]]; then
    set -x
fi

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

while read -r param; do
	r[req_headers]+="$param"
	param_l="${param,,}" # lowercase
	name=''
	value=''
	data=''
	unset IFS

	# TODO: think about refactoring those ifs; maybe we *don't* need to have a header "allowlist" afterall...
	
	if [[ "$param_l" == $'\015' ]]; then
		break
		
	elif [[ "$param_l" == "content-length:"* ]]; then
		r[content_length]="$(sed 's/Content-Length: //i;s/\r//' <<< "$param")"

	elif [[ "$param_l" == "content-type:"* ]]; then
		r[content_type]="$(sed 's/Content-Type: //i;s/\r//' <<< "$param")"
		if [[ "${r[content_type]}" == *"multipart/form-data"* ]]; then
			tmpdir=$(mktemp -d)
		fi
		if [[ "${r[content_type]}" == *"boundary="* ]]; then
			r[content_boundary]="$(sed -E 's/(.*)boundary=//i;s/\r//;s/ //' <<< "${r[content_type]}")"
		fi
		
	elif [[ "$param_l" == "host:"* ]]; then
		r[host]="$(sed 's/Host: //i;s/\r//;s/\\//g' <<< "$param")"
		r[host_portless]="$(sed -E 's/:(.*)$//' <<< "${r[host]}")"
		if [[ -f "config/$(basename -- ${r[host]})" ]]; then
			source "config/$(basename -- ${r[host]})"
		elif [[ -f "config/$(basename -- ${r[host_portless]})" ]]; then
			source "config/$(basename -- ${r[host_portless]})"
		fi

	elif [[ "$param_l" == "user-agent:"* ]]; then
		r[user_agent]="$(sed 's/User-Agent: //i;s/\r//;s/\\//g' <<< "$param")"
		
	elif [[ "$param_l" == "upgrade:"* && $(sed 's/Upgrade: //i;s/\r//' <<< "$param") == "websocket" ]]; then
		r[status]=101
		
	elif [[ "$param_l" == "sec-websocket-key:"* ]]; then
		r[websocket_key]="$(sed 's/Sec-WebSocket-Key: //i;s/\r//' <<< "$param")"
		
	elif [[ "$param_l" == "authorization: basic"* ]]; then
		login_simple "$param"
		
	elif [[ "$param_l" == "authorization: bearer"* ]]; then
		r[authorization]="$(sed 's/Authorization: Bearer //i;s/\r//' <<< "$param")"

	elif [[ "$param_l" == "cookie: "* ]]; then
		IFS=';'
		for i in $(IFS=' '; echo "$param" | sed -E 's/Cookie: //i;;s/%/\\x/g'); do
			name="$((grep -Poh "[^ ].*?(?==)" | head -1) <<< $i)"
			value="$(sed "s/$name=//;s/^ //;s/ $//" <<< $i)"
			cookies[$name]="$(echo -e $value)"
		done

	elif [[ "$param_l" == "range: bytes="* ]]; then
		r[range]="$(sed 's/Range: bytes=//;s/\r//' <<< "$param")"
		
	elif [[ "$param_l" =~ ^(get|post|patch|put|delete|meow) ]]; then # TODO: OPTIONS, HEAD
		r[method]="${param%% *}"
		[[ "${r[method],,}" != "get" ]] && r[post]=true
		r[url]="$(sed -E 's/^[a-zA-Z]* //;s/HTTP\/[0-9]+\.[0-9]+//;s/ //g;s/\/*\r//g;s/\/\/*/\//g' <<< "$param")"

		IFS='&'
		for i in ${r[url]#*\?}; do
			name="$(url_decode "${i%%=*}")"
			value="$(url_decode "${i#*=}")"
			get_data[$name]="$value"
		done
		unset IFS
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

echo "$(date) - IP: ${r[ip]}, PROTO: ${r[proto]}, URL: ${r[url]}, GET_data: ${get_data[@]}, POST_data: ${post_data[@]}, POST_multipart: ${post_multipart[@]}, UA: ${r[user_agent]}" >> "${cfg[namespace]}/${cfg[log]}"

[[ -f "${cfg[namespace]}/routes.sh" ]] && source "${cfg[namespace]}/routes.sh"

if [[ ${r[status]} != 101 ]]; then
	clean_url="$(sed -E 's/\?.*//' <<< "${r[url]}")"
	for (( i=0; i<${#route[@]}; i=i+3 )); do
		if [[ "$(grep -Poh "^${route[$((i+1))]}$" <<< "$clean_url")" != "" ]] || [[ "$(grep -Poh "^${route[$((i+1))]}$" <<< "$clean_url/")" != "" ]]; then
			r[status]=212
			r[view]="${route[$((i+2))]}"
			IFS='/'
			url=(${route[$i]})
			url_=($(cut -d '?' -f 1 <<< "${r[url]}"))
			unset IFS
			for (( j=0; j<${#url[@]}; j++ )); do
				if [[ ${url_[$j]} != '' && ${url[$j]} == ":"* ]]; then
					params[$(sed 's/://' <<< "${url[$j]}")]="${url_[$j]}"
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
		
		IFS='&'
		for i in $(tr -d '\n' <<< "$data"); do
			name="${i/=*/}"
			param="${i/*=/}"
			post_data[$name]="$param"
		done
		unset IFS
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
