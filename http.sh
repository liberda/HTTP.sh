#!/bin/bash
trap ctrl_c INT

function ctrl_c() {
	pkill -P $$
	echo -e "Killed all remaining processes.\nHave a great day!!"
}

source config/master.sh
echo "HTTP.sh"

if [[ ${cfg[ssl]} == true ]]; then
	echo "listening on port ${cfg[port]} (HTTP) and ${cfg[ssl_port]} (HTTPS)"
	ncat -v -l -p ${cfg[port]} -c ./src/server.sh -k 2>> ${cfg[log_http]} &
	if [[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]]; then
		ncat -v -l -p ${cfg[ssl_port]} -c ./src/server.sh -k --ssl --ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]} 2>> ${cfg[log_https]}
	else
		ncat -v -l -p ${cfg[ssl_port]} -c ./src/server.sh -k --ssl 2>> ${cfg[log_https]}
	fi
else
	echo "listening on port ${cfg[port]} (HTTP)"
	ncat -v -l -p ${cfg[port]} -c ./src/server.sh -k 2>> ${cfg[log_http]}
fi

