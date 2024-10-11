#!/usr/bin/env bash
trap ctrl_c INT
ctrl_c() {
	[[ $socket != '' ]] && rm $socket
	pkill -P $$
	echo -e "Cleaned up, exitting.\nHave an awesome day!!"
}

setup_config() {
	[[ ! "$1" ]] && namespace=app || namespace="$1"

	mkdir -p config
	cp ".resources/primary_config.sh" "config/master.sh"
	echo "cfg[namespace]=$namespace # default namespace" >> "config/master.sh"
	echo "cfg[init_version]=$HTTPSH_VERSION" >> "config/master.sh"
}

if [[ ! -f "$PWD/http.sh" ]]; then
		echo -e "Please run HTTP.sh inside its designated directory\nRunning the script from arbitrary locations isn't supported."
		exit 1
fi
source src/version.sh

if [[ "$1" == "init" ]]; then # will get replaced with proper parameter parsing in 1.0
	[[ ! "$2" ]] && namespace=app || namespace="$2"

	if [[ ! -f "config/master.sh" ]]; then
		setup_config
	elif [[ -d "$namespace" ]]; then
		echo -e "ERR: HTTP.sh has been initialized before.\nSpecify a new namespace directory, or perish (remove '$namespace'?)"
		exit 1
	else
		echo "WARN: HTTP.sh has been initialized before. Continuing w/o recreating config."
	fi
	source config/master.sh
	
	mkdir -p "${cfg[namespace]}/${cfg[root]}" "${cfg[namespace]}/workers/example" "${cfg[namespace]}/views" "${cfg[namespace]}/templates"
	touch "${cfg[namespace]}/config.sh" "${cfg[namespace]}/workers/example/control"
	cp ".resources/config.sh" "${cfg[namespace]}/config.sh"
	cp ".resources/routes.sh" "${cfg[namespace]}/routes.sh"

	cp .resources/example_worker/* "${cfg[namespace]}/workers/example/"
	cp .resources/example_webroot/* "${cfg[namespace]}/${cfg[root]}/index.shs"
	
	echo -e "Success..?\nTry running \`./http.sh\` now"
	exit 0

elif [[ ! -f "config/master.sh" ]]; then
	if [[ -d "app" ]]; then # if the de-facto default app dir already exists, copy the cfg
		setup_config
	else
		echo "ERR: Initialize HTTP.sh first! run './http.sh init'"
		exit 1
	fi
fi
source config/master.sh

if [[ "$HTTPSH_VERSION" != "${cfg[init_version]}" ]]; then
	echo "WARN: HTTP.sh was updated since this instance was initialized (config v${cfg[init_version]:-(none)}, runtime v$HTTPSH_VERSION). There may be breaking changes. Edit cfg[init_version] in config/master.sh to remove this warning."
fi	

while read i; do
	if ! which $i > /dev/null 2>&1; then
		echo "ERROR: can't find $i"
		error=true
	fi
done < src/dependencies.required

while read i; do
	which $i > /dev/null 2>&1
	[[ $? != 0 ]] && echo "WARNING: can't find $i"
done < src/dependencies.optional

if ! which ncat > /dev/null 2>&1; then
	if [[ ${cfg[socat_only]} != true ]]; then
		echo "ERR: can't find ncat, and cfg[socat_only] is not set to true"
		error=true
	fi
fi

if [[ $error == true ]]; then
	echo "Fix above dependencies, and I might just let you pass."
	exit 1
fi

if [[ "$1" == 'shell' ]]; then
	bash --rcfile <(echo '
	shopt -s extglob
	x() { declare -p data;} # for notORM
	source config/master.sh
	source src/account.sh
	source src/mail.sh
	source src/mime.sh
	source src/misc.sh
	source src/notORM.sh
	source src/template.sh
	source "${cfg[namespace]}/config.sh"
	PS1="[HTTP.sh] \[\033[01;34m\]\w\[\033[00m\]\$ "')
	exit 0
fi

cat <<EOF >&2
 _    _ _______ _______ _____  ______ _    _ 
| |  | |_______|_______|  _  \/  ___/| |  | |
| |__| |  | |     | |  | |_| | |___  | |__| |
| |__| |  | |     | |  |  ___/\___ \ | |__| |
| |  | |  | |     | |  | |     ___\ \| |  | |
|_|  |_|  |_|     |_|  |_|  □ /_____/|_|  |_| v$HTTPSH_VERSION
EOF

if [[ "$1" == "debug" ]]; then
	cfg[dbg]=true
	echo "[DEBUG] Activated debug mode - stderr will be shown"
elif [[ "$1" == "debuggier" ]]; then
    cfg[dbg]=true
    cfg[debuggier]=true
    export PS4=' ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    echo "[DEBUG] Activated debuggier mode - stderr and call trace will be shown"
    set -x
fi

source src/worker.sh

if [[ -f "${cfg[namespace]}/config.sh" ]]; then
	source "${cfg[namespace]}/config.sh"
fi

if [[ ${cfg[socat_only]} == true ]]; then
	echo "[INFO] listening directly via socat, assuming no ncat available"
	echo "[HTTP] listening on ${cfg[ip]}:${cfg[port]}"
	if [[ ${cfg[dbg]} == true ]]; then
		socat tcp-listen:${cfg[port]},bind=${cfg[ip]},fork "exec:bash -c \'src/server.sh ${cfg[debuggier]}\'"
	else
		socat tcp-listen:${cfg[port]},bind=${cfg[ip]},fork "exec:bash -c src/server.sh" 2>> /dev/null
		if [[ $? != 0 ]]; then
			echo "[WARN] socat quit with a non-zero status; Maybe the port is in use?"
		fi
	fi
else
	if [[ ${cfg[http]} == true ]]; then
		# this is a workaround because ncat kept messing up large (<150KB) files over HTTP - but not over HTTPS!
		socket=$(mktemp -u /tmp/socket.XXXXXX)
		if [[ ${cfg[dbg]} == true ]]; then
			# ncat with the "timeout" (-i) option has a bug which forces it
			# to quit after the first time-outed connection, ignoring the
			# "broker" (-k) mode. This is a workaround for this. 
			while true; do
				ncat -i 600s -l -U "$socket" -c "src/server.sh ${cfg[debuggier]}" -k
			done &
		else
			while true; do
				ncat -i 600s -l -U "$socket" -c src/server.sh -k 2>> /dev/null
			done &
		fi
		socat TCP-LISTEN:${cfg[port]},fork,bind=${cfg[ip]} UNIX-CLIENT:$socket &
		echo "[HTTP] listening on ${cfg[ip]}:${cfg[port]} through '$socket'"
	fi

	if [[ ${cfg[ssl]} == true ]]; then
		echo "[SSL] listening on port ${cfg[ip]}:${cfg[ssl_port]}"
		if [[ ${cfg[dbg]} == true ]]; then
			while true; do
				ncat -i 600s -l ${cfg[ip]} ${cfg[ssl_port]} -c src/server.sh -k --ssl $([[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]] && echo "--ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]}")
			done &
		else
			while true; do
				ncat -i 600s -l ${cfg[ip]} ${cfg[ssl_port]} -c src/server.sh -k --ssl $([[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]] && echo "--ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]}") 2>> /dev/null
			done &
		fi
	fi
fi

wait
