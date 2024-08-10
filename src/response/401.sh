echo -ne "HTTP/1.0 401 Unauthorized
WWW-Authenticate: Basic realm=\"${cfg[auth_realm]}\"
${cfg[extra_headers]}\r\n"
