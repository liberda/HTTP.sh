#!/bin/bash
url="$(url_decode "$(url_decode "$(sed -E 's/\?/��Lun4_iS_CuTe�/;s/^(.*)��Lun4_iS_CuTe�//;s/'"${cfg[proxy_param]}"'=//g' <<< "${r[url]}")")")"

if [[ $(grep -Poh "${cfg[proxy_url]}" <<< "$url") == '' ]]; then
	exit 1
fi

host="$(sed -E 's@http(s|)://@@;s@/.*@@' <<< "$url")"
headers="$(tr '\r' '\n' <<< "${r[req_headers]}")"
headers+=$'\n'

while read line; do
	if [[ "$line" == "GET"* ]]; then
		if [[ "$url" == *"$host" ]]; then
			echo "GET / HTTP/1.1"
		else
			echo "GET /$(sed -E 's@http(s|)://@@;s@/@��Lun4_iS_CuTe�@;s@.*��Lun4_iS_CuTe�@@' <<< "$url") HTTP/1.1"
		fi
	elif [[ "$line" == *"Host"* ]]; then
		echo "Host: $url" | sed -E 's@http(s|)://@@;s@/.*@@'
	else
		echo "$line"
	fi
done <<< "$headers" | if [[ "$url" == "https"* ]]; then
	nc $host 443 --ssl -C -i 0.1 --no-shutdown
else
	nc $host 80 -C -i 0.1 --no-shutdown
fi
