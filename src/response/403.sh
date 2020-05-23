printf "HTTP/1.0 403 Forbidden
${cfg[extra_headers]}\r\n\r\n"
source templates/head.sh
echo "<h1>403: You've been naughty</h1>"
