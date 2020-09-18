#!/bin/bash
trap ctrl_c INT

function ctrl_c() {
	pkill -P $$
	echo -e "Killed all remaining processes.\nHave a great day!!"
}

source src/worker.sh

if [[ -f "config/app.sh" ]]; then
	source config/app.sh
fi

source config/master.sh
echo "HTTP.sh"

if [[ ${cfg[http]} == true ]]; then
	echo "[HTTP] listening on ${cfg[ip]}:${cfg[port]}"
	ncat -v -l ${cfg[ip]} ${cfg[port]} -c ./src/server.sh -k 2>> /dev/null &
fi

if [[ ${cfg[ssl]} == true ]]; then
	echo "[SSL] listening on port ${cfg[ip]}:${cfg[ssl_port]}"
	if [[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]]; then
		ncat -v -l ${cfg[ip]} ${cfg[ssl_port]} -c ./src/server.sh -k --ssl --ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]} 2>> /dev/null &
	else
		ncat -v -l ${cfg[ip]} ${cfg[ssl_port]} -c ./src/server.sh -k --ssl 2>> /dev/null &
	fi
fi

wait