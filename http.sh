#!/bin/bash
trap ctrl_c INT
source config/master.sh

function ctrl_c() {
	[[ $socket != '' ]] && rm $socket
	pkill -P $$
	echo -e "Cleaned up, exitting.\nHave an awesome day!!"
}

if [[ ! -f "$(pwd)/http.sh" ]]; then
		echo -e "Please run HTTP.sh inside it's designated directory\nRunning the script from arbitrary locations isn't supported."
		exit 1
fi	


for i in $(cat src/dependencies.required); do
	which $i > /dev/null 2>&1
	if [[ $? != 0 ]]; then
		echo "ERROR: can't find $i"
		error=true
	fi
done
for i in $(cat src/dependencies.optional); do
	which $i > /dev/null 2>&1
	[[ $? != 0 ]] && echo "WARNING: can't find $i"
done

if [[ $error == true ]]; then
	echo "Fix above dependencies, and we might just let you pass."
	exit 0
fi

if [[ $1 == "init" ]]; then # will get replaced with proper parameter parsing in 1.0
	mkdir -p "${cfg[namespace]}/${cfg[root]}" "${cfg[namespace]}/workers/example" "${cfg[namespace]}/views" "${cfg[namespace]}/templates"
	touch "${cfg[namespace]}/config.sh" "${cfg[namespace]}/workers/example/control"
	cat <<LauraIsCute > "${cfg[namespace]}/config.sh"
## app config
## your application-specific config goes here!


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
	cat <<PtrcIsCute > "${cfg[namespace]}/routes.sh"
## routes - application-specific routes
##
## HTTP.sh supports both serving files using a directory structure (webroot),
## and using routes. The latter may come in handy if you want to create nicer
## paths, e.g.
##
## (webroot) https://example.com/profile.shs?name=ptrcnull
## ... may become ...
## (routes)  https://example.com/profile/ptrcnull
##
## To set up routes, define rules in this file (see below for examples)

# router "/test" "app/views/test.shs"
# router "/profile/:user" "app/views/user.shs"
PtrcIsCute

	chmod +x "${cfg[namespace]}/workers/example/worker.sh"
	
	echo -e "Success..?\nTry running ./http.sh now"
	exit 0
fi

cat <<PtrcIsCute >&2
 _    _ _______ _______ _____  ______ _    _ 
| |  | |_______|_______|  _  \/  ___/| |  | |
| |__| |  | |     | |  | |_| | |___  | |__| |
| |__| |  | |     | |  |  ___/\___ \ | |__| |
| |  | |  | |     | |  | |     ___\ \| |  | |
|_|  |_|  |_|     |_|  |_|  □ /_____/|_|  |_|
PtrcIsCute

if [[ $1 == "debug" ]]; then
	cfg[dbg]=true
	echo "[DEBUG] Activated debug mode - stderr will be shown"
fi

source src/worker.sh

if [[ -f "${cfg[namespace]}/config.sh" ]]; then
	source "${cfg[namespace]}/config.sh"
fi

if [[ ${cfg[http]} == true ]]; then
	# this is a workaround because ncat kept messing up large (<150KB) files over HTTP - but not over HTTPS!
	socket=$(mktemp -u /tmp/XXXX.socket)
	if [[ ${cfg[dbg]} == true ]]; then
		ncat -l -U "$socket" -c src/server.sh -k &
	else
		ncat -l -U "$socket" -c src/server.sh -k 2>> /dev/null &
	fi
	socat TCP-LISTEN:${cfg[port]},fork,bind=${cfg[ip]} UNIX-CLIENT:$socket &
	echo "[HTTP] listening on ${cfg[ip]}:${cfg[port]} through '$socket'"
	#ncat -v -l ${cfg[ip]} ${cfg[port]} -c ./src/server.sh -k 2>> /dev/null &
fi

if [[ ${cfg[ssl]} == true ]]; then
	echo "[SSL] listening on port ${cfg[ip]}:${cfg[ssl_port]}"
	if [[ ${cfg[dbg]} == true ]]; then
		ncat -l ${cfg[ip]} ${cfg[ssl_port]} -c src/server.sh -k --ssl $([[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]] && echo "--ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]}") &
	else
		ncat -l ${cfg[ip]} ${cfg[ssl_port]} -c src/server.sh -k --ssl $([[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]] && echo "--ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]}") 2>> /dev/null &
	fi
fi

wait
