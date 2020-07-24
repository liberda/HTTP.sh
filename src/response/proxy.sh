printf "HTTP/1.0 200 OK
${cfg[extra_headers]}\r\n\r\n"

curl ${cfg[proxy_url]}${r[url]}