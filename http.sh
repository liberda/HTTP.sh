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
	ncat -l -p ${cfg[port]} -c ./src/server.sh -k &
	if [[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]]; then
		ncat -l -p ${cfg[ssl_port]} -c ./src/server.sh -k --ssl --ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]}
	else
		ncat -l -p ${cfg[ssl_port]} -c ./src/server.sh -k --ssl
	fi
else
	echo "listening on port ${cfg[port]} (HTTP)"
	ncat -l -p ${cfg[port]} -c ./src/server.sh -k
fi

