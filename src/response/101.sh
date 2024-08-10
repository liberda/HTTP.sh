echo "HTTP/1.1 101 Web Socket Protocol Handshake
Connection: Upgrade
Upgrade: WebSocket
${cfg[extra_headers]}"
if [[ ${r[websocket_key]} != '' ]]; then
	accept=$(echo -ne $(echo "${r[websocket_key]}""258EAFA5-E914-47DA-95CA-C5AB0DC85B11" | sha1sum | sed 's/ //g;s/-//g;s/.\{2\}/\\x&/g') | base64)
	echo "Sec-WebSocket-Accept: "$accept
fi
echo -e "\r\n\r\n"

#echo "Laura is cute <3"
#WebSocket-Location: ws://localhost:1337/
#WebSocket-Origin: http://localhost:1337/\r\n\r\n  "

source ./src/ws.sh 

#input=''
#while read -N 1 chr; do
#	input=$input$chr
#	if [[ $chr == "\r" ]]; then
#		break
#	fi
#done


exit 0
#while true; do
#	read test
#	echo $test
#	sleep 1
#done
