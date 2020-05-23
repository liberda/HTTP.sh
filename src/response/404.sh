printf "HTTP/1.0 404 Not Found
${cfg[extra_headers]}\r\n\r\n"
source templates/head.sh
echo "<h1>404 Not Found</h1>"
