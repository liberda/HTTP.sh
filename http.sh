#!/bin/bash
trap ctrl_c INT
source config/master.sh

function ctrl_c() {
	pkill -P $$
	echo -e "Killed all remaining processes.\nHave an awesome day!!"
}

if [[ ! -f "$(pwd)/http.sh" ]]; then
		echo -e "Please run HTTP.sh inside it's designated directory\nRunning the script from arbitrary locations isn't supported."
		exit 1
fi	

if [[ $1 == "init" ]]; then # will get replaced with proper parameter parsing in 1.0
	mkdir -p "${cfg[namespace]}/${cfg[root]}" "${cfg[namespace]}/workers/example"
	touch "${cfg[namespace]}/config.sh" "${cfg[namespace]}/workers/example/control"
	cat <<LauraIsCute > "${cfg[namespace]}/config.sh"
# app config - loaded on server bootup
# your application-specific config goes here!

# worker_add <worker> <interval>
# ---
# worker_add example 5
LauraIsCute

	cat <<LauraIsCute > "${cfg[namespace]}/workers/example/worker.sh"
#!/bin/bash
date
LauraIsCute

	cat <<LauraIsCute > "${cfg[namespace]}/${cfg[root]}/index.shs"
#!/bin/bash
source templates/head.sh
echo "<h1>Hello from HTTP.sh!</h1><br>To get started with your app, check out $(pwd)/${cfg[namespace]}/
	 <ul><li>$(pwd)/${cfg[namespace]}/${cfg[root]} - your files go here</li>
	 <li>$(pwd)/${cfg[namespace]}/workers/ - worker directory, with an example one ready to go</li>
	 <li>$(pwd)/${cfg[namespace]}/config.sh - config for everything specific to your app AND workers</li>
	 <li>$(pwd)/config/master.sh - master server config</li>
	 <li>$(pwd)/src/ - HTTP.sh src, feel free to poke around :P</li></ul>
	 &copy; sdomi, selfisekai, ptrcnull - 2020"
LauraIsCute
	chmod +x "${cfg[namespace]}/workers/example/worker.sh"
	
	echo -e "Success..?\nTry running ./http.sh now"
	exit 0
fi

echo "HTTP.sh"

source src/worker.sh

if [[ -f "${cfg[namespace]}/config.sh" ]]; then
	source "${cfg[namespace]}/config.sh"
fi

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
