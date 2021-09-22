#!/usr/bin/env bash
url="$(url_decode "$(url_decode "$(sed -E 's/\?/��Lun4_iS_CuTe�/;s/^(.*)��Lun4_iS_CuTe�//;s/'"${cfg[proxy_param]}"'=//g' <<< "${r[url]}")")")"

if [[ $(grep -Poh "${cfg[proxy_url]}" <<< "$url") == '' ]]; then
	exit 1
fi

host="$(sed -E 's@http(s|)://@@;s@/.*@@' <<< "$url")"
proxy_url="$(sed -E 's/\?.*//g' <<< "${r[url]}")"
headers="$(tr '\r' '\n' <<< "${r[req_headers]}")"
headers+=$'\n'
#params=()

while read line; do
	if [[ "$line" != "GET"* && "$line" != "Host:"* && "$line" != '' ]]; then
		args+=('-H')
		args+=("$line")
	fi
done <<< "$headers"

curl --http1.1 "$url" "${args[@]}" -D /dev/stdout | grep -aiv "Transfer-Encoding: chunked" | sed -E '/Location/s/\?/%3f/g;/Location/s/\&/%26/g;/Location/s/\:/%3a/g;/Location/s@/@%2f@g;s@Location%3a @Location: '"$proxy_url"'?'"${cfg[proxy_param]}"'=@'

