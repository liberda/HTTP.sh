#!/usr/bin/env bash
[[ ! -f src/libsh/bin/bin.sh ]] && return # no websocket for you! clone the repo
source src/libsh/bin/bin.sh

if [[ "${r[status]}" == 101 && "${r[url_clean]}" != *\.${cfg[extension_websocket]} ]] ||
   [[ "${r[status]}" == 102 && "${r[view]}" != *\.${cfg[extension_websocket]} ]]; then
	echo "Rejecting an invalid WebSocket connection." >&2
	declare -p r >&2
	return
fi

echo "HTTP/1.1 101 Web Socket Protocol Handshake
Connection: Upgrade
Upgrade: WebSocket
${cfg[extra_headers]}"
if [[ ${r[websocket_key]} != '' ]]; then
	accept=$(echo -ne $(echo -n "${r[websocket_key]}""258EAFA5-E914-47DA-95CA-C5AB0DC85B11" | sha1sum | sed 's/ //g;s/-//g;s/.\{2\}/\\x&/g') | base64)
	echo -n "Sec-WebSocket-Accept: $accept"
fi
echo -ne "\r\n\r\n"

source ./src/ws.sh 
unset IFS

if [[ "${r[status]}" == 101 ]]; then
	source "${r[uri]}"
elif [[ "${r[status]}" == 102 ]]; then
	source "${r[view]}"
fi
