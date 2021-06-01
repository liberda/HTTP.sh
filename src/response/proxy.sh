#!/bin/bash
url="$(url_decode "$(url_decode "$(sed -E 's/\?/��Lun4_iS_CuTe�/;s/^(.*)��Lun4_iS_CuTe�//;s/'"${cfg[proxy_param]}"'=//g' <<< "${r[url]}")")")"

if [[ $(grep -Poh "${cfg[proxy_url]}" <<< "$url") == '' ]]; then
	exit 1
fi

host="$(sed -E 's@http(s|)://@@;s@/.*@@' <<< "$url")"
proxy_url="$(sed -E 's/\?.*//g' <<< "${r[url]}")"
headers="$(tr '\r' '\n' <<< "${r[req_headers]}")"
headers+=$'\n'

while read line; do
	if [[ "$line" != "GET"* && "$line" != "Host:"* && "$line" != '' ]]; then
		params+="-H '$line' "
	fi
done <<< "$headers"

curl -v --http1.1 "$url" "$params" -D /dev/stdout | grep -aiv "Transfer-Encoding: chunked" | sed -E 's@Location: @Location: '"$proxy_url"'?'"${cfg[proxy_param]}"'=@'
