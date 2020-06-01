#!/bin/bash
source config/master.sh
source src/mime.sh
source src/misc.sh
source src/account.sh

declare -A r # current request / response
declare -A meta # metadata for templates
declare -A cookies # cookies!

r[status]=210 # Mommy always said that I was special
post_length=0
post=false
get=false

while read param; do
	if [[ $param == $'\015' ]]; then
		break
		
	elif [[ $param == *"Content-Length:"* ]]; then
		r[content_length]=$(echo -n $param | sed 's/Content-Length: //;s/\r//')

	elif [[ $param == *"Content-Type:"* ]]; then
		r[content_type]=$(echo -n $param | sed 's/Content-Type: //;s/\r//')
		if [[ ${r[content_type]} == *"multipart/form-data"* ]]; then
			tmpdir=$(mktemp -d)
		fi
		if [[ ${r[content_type]} == *"boundary="* ]]; then
			r[content_boundary]=$(echo -n ${r[content_type]} | sed -E 's/(.*)boundary=//;s/\r//;s/ //')
		fi
		
	elif [[ $param == *"Host:"* ]]; then
		r[host]=$(printf "$param" | sed 's/Host: //;s/\r//')
		r[host_portless]=$(echo ${r[host]} | sed -E 's/:(.*)$//')
		if [[ -f "config/${r[host]}" ]]; then
			source "config/${r[host]}"
		elif [[ -f "config/${r[host_portless]}" ]]; then
			source "config/${r[host_portless]}"
		fi
		
	elif [[ $param == *"Upgrade:"* && $(printf "$param" | sed 's/Upgrade: //;s/\r//') == "websocket" ]]; then
		r[status]=101
		
	elif [[ $param == *"Sec-WebSocket-Key:"* ]]; then
		r[websocket_key]=$(printf "$param" | sed 's/Sec-WebSocket-Key: //;s/\r//')
		
	elif [[ $param == *"Authorization: Basic"* ]]; then
		login_simple $param

	elif [[ $param == *"Cookie: "* ]]; then
		for i in $(echo $param | sed -E 's/Cookie: //;s/\;//g;s/%/\\x/g'); do
			name=$(echo $i | sed -E 's/\=(.*)$//')
			value=$(echo $i | sed -E 's/^(.*)\=//')
			cookies[$name]=$(echo -e $value)
		done
		
	elif [[ $param == *"GET "* ]]; then
		r[url]=$(echo -ne "$(echo -n $param | sed -E 's/GET //;s/HTTP\/[0-9]+\.[0-9]+//;s/ //g;s/\%/\\x/g;s/\/*\r//g;s/\/\/*/\//g')")
		data=$(echo ${r[url]} | sed -E 's/^(.*)\?//;s/\&/ /g')
		if [[ $data != ${r[url]} ]]; then
			declare -A get_data
			for i in $data; do
				name=$(echo $i | sed -E 's/\=(.*)$//')
				value=$(echo $i | sed "s/$name\=//")
				get_data[$name]=$value
			done
		fi
		
	elif [[ $param == *"POST "* ]]; then
		r[url]=$(echo -ne "$(echo -n $param | sed -E 's/POST //;s/HTTP\/[0-9]+\.[0-9]+//;s/ //g;s/\%/\\x/g;s/\/*\r//g;s/\/\/*/\//g')")	
		r[post]=true
		# below shamelessly copied from GET, should be moved to a function
		data=$(echo ${r[url]} | sed -E 's/^(.*)\?//;s/\&/ /g')
		if [[ $data != ${r[url]} ]]; then
			declare -A get_data
			for i in $data; do
				name=$(echo $i | sed -E 's/\=(.*)$//')
				value=$(echo $i | sed "s/$name\=//")
				get_data[$name]=$value
			done
		fi
		
	fi
done

r[uri]=$(realpath ${cfg[root]}$(echo ${r[url]} | sed -E 's/\?(.*)$//'))
[[ -d "${r[uri]}/" ]] && pwd="${r[uri]}" || pwd=$(dirname "${r[uri]}")


echo "---" >> ${cfg[log_misc]}
echo "$(date)" >> ${cfg[log_misc]}
if [[ $(tail -n 1 ${cfg[log_http]}) == $(cat /tmp/lasthttp) ]]; then
	r[ip]=$(tail -n 1 ${cfg[log_https]} | sed -s 's/Ncat: Connection from //')
	r[proto]='http'
	echo "HTTPS IP: ${r[ip]}" >> ${cfg[log_misc]}
else
	r[ip]=$(tail -n 1 ${cfg[log_http]} | sed -s 's/Ncat: Connection from //')
	r[proto]='https'
	echo "HTTP IP: ${r[ip]}" >> ${cfg[log_misc]}
fi
echo "URL: ${r[url]}, GET_data: ${get_data[@]}, POST_data: ${post_data[@]}, POST_multipart: ${post_multipart[@]}" >> ${cfg[log_misc]}
tail -n 1 ${cfg[log_http]} > /tmp/lasthttp


if [[ ${r[status]} != 101 ]]; then
	if [[ -a ${r[uri]} && ! -r ${r[uri]} ]]; then
		r[status]=403
	elif [[ "$(echo -n ${r[uri]})" != "$(realpath ${cfg[root]})"* ]]; then
		r[status]=403
	elif [[ -f ${r[uri]} ]]; then
		r[status]=200
	elif [[ -d ${r[uri]} ]]; then
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

if [[ ${cfg[auth_required]} == true && ${r[authorized]} != true ]]; then
	echo "Auth failed." >> ${cfg[log_misc]}
	r[status]=401
fi

if [[ ${r[post]} == true && ${r[status]} == 200 ]]; then

	# This whole ordeal is here to prevent passing binary data as a variable.
	# I could have done it as an array, but this solution works, and it's
	# speedy enough so I don't care.

	if [[ $tmpdir ]]; then
		declare post_multipart
		tmpfile=$(mktemp -p $tmpdir)
		dd iflag=fullblock of=$tmpfile ibs=${r[content_length]} count=1 obs=1M
		
		delimeter_len=$(echo -n "$content_boundary"$'\015' | wc -c)
		boundaries_list=$(echo -ne $(grep $tmpfile -ao -e ${r[content_boundary]} --byte-offset | sed -E 's/:(.*)//g') | sed -E 's/ [0-9]+$//')
		
		for i in $boundaries_list; do
			tmpout=$(mktemp -p $tmpdir)
			dd iflag=fullblock if=$tmpfile ibs=$(($i+$delimeter_len)) obs=1M skip=1 | while true; do
				read line
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
		read -N ${r[content_length]} data
		declare -A post_data
		
		for i in $(echo $data | sed -s 's/\&/ /g;'); do
			name=$(echo $i | sed -E 's/\=(.*)$//')
			param=$(echo $i | sed "s/$name\=//")
			post_data[$name]=$param
		done
	fi
fi

if [[ ${r[status]} == 210 && ${cfg[autoindex]} == true ]]; then
	source "src/response/listing.sh"
elif [[ ${r[status]} == 200 ]]; then
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
