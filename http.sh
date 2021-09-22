#!/usr/bin/env bash
trap ctrl_c INT

if [[ ! -f "config/master.sh" ]]; then
	mkdir -p config
	cat <<PtrcIsCute > "config/master.sh"
declare -A cfg

cfg[ip]=127.0.0.1 # IP address to bind to - use 0.0.0.0 to bind to all

cfg[http]=true # enables/disables listening on HTTP
cfg[port]=1337 # HTTP port
cfg[socat_only]=false

cfg[namespace]='app'

cfg[root]='webroot/' 
cfg[index]='index.shs'
cfg[autoindex]=true

cfg[auth_required]=false
cfg[auth_realm]="Luna is cute <3"

cfg[ssl]=false # enables/disables listening on HTTPS
cfg[ssl_port]=8443
cfg[ssl_cert]=''
cfg[ssl_key]=''

cfg[extension]='shs'
cfg[extra_headers]='server: HTTP.sh/0.94 (devel)'

cfg[title]='HTTP.sh 0.94'

cfg[php_enabled]=false # enable PHP script evalutaion (requires PHP)
cfg[python_enabled]=false # enable Python script evalutaion (requires Python)

cfg[log]='log' # filename

cfg[proxy]=false # you probably want to configure this per-url
cfg[proxy_url]='' # regexp matching valid URLs to proxy
cfg[proxy_param]='url' # /proxy?url=...

# mail handler config
cfg[mail]=""
cfg[mail_server]=""
cfg[mail_password]=""
cfg[mail_ssl]=true
cfg[mail_ignore_bad_cert]=false
PtrcIsCute
fi

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

which ncat > /dev/null 2>&1
if [[ $? != 0 ]]; then
	if [[ ${cfg[socat_only]} != true ]]; then
		echo "ERROR: can't find ncat, and cfg[socat_only] is not set to true"
		error=true
	fi
fi

if [[ $error == true ]]; then
	echo "Fix above dependencies, and I might just let you pass."
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
#!/usr/bin/env bash
date
LauraIsCute

	cat <<LauraIsCute > "${cfg[namespace]}/${cfg[root]}/index.shs"
#!/usr/bin/env bash
source templates/head.sh
echo "<h1>Hello from HTTP.sh!</h1><br>To get started with your app, check out $(pwd)/${cfg[namespace]}/
	 <ul><li>$(pwd)/${cfg[namespace]}/${cfg[root]} - your (public) files go here</li>
	 <li>$(pwd)/${cfg[namespace]}/workers/ - worker directory, with an example one ready to go</li>
	 <li>$(pwd)/${cfg[namespace]}/views/ - individual views can be stored there, to be later referenced by routes.sh</li>
	 <li>$(pwd)/${cfg[namespace]}/templates/ - template files (.t) live over there</li>
	 <li>$(pwd)/${cfg[namespace]}/config.sh - config for everything specific to your app AND workers</li>
	 <li>$(pwd)/${cfg[namespace]}/routes.sh - config for the HTTP.sh router</li></ul>
	 Fun things outside of the app directory:
	 <ul><li>$(pwd)/config/master.sh - master server config</li>
	 <li>$(pwd)/config/<hostname> - config loaded if a request is made to a specific hostname</li>
	 <li>$(pwd)/storage/ - directory for storing all and any data your app may produce</li>
	 <li>$(pwd)/secret/ - user accounts and other secret tokens live here</li>
	 <li>$(pwd)/src/ - HTTP.sh src, feel free to poke around ;P</li></ul> 
	 &copy; sdomi, ptrcnull, selfisekai - 2020, 2021"
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

if [[ "$1" == "debug" ]]; then
	cfg[dbg]=true
	echo "[DEBUG] Activated debug mode - stderr will be shown"
fi

source src/worker.sh

if [[ -f "${cfg[namespace]}/config.sh" ]]; then
	source "${cfg[namespace]}/config.sh"
fi

if [[ ${cfg[socat_only]} == true ]]; then
	echo "[INFO] listening directly via socat, assuming no ncat available"
	echo "[HTTP] listening on ${cfg[ip]}:${cfg[port]}"
	if [[ ${cfg[dbg]} == true ]]; then
		socat tcp-listen:${cfg[port]},bind=${cfg[ip]},fork "exec:bash -c src/server.sh"
	else
		socat tcp-listen:${cfg[port]},bind=${cfg[ip]},fork "exec:bash -c src/server.sh" 2>> /dev/null
		if [[ $? != 0 ]]; then
			echo "[WARN] socat exitted with a non-zero status; Maybe the port is in use?"
		fi
	fi
else
	if [[ ${cfg[http]} == true ]]; then
		# this is a workaround because ncat kept messing up large (<150KB) files over HTTP - but not over HTTPS!
		socket=$(mktemp -u /tmp/socket.XXXXXX)
		if [[ ${cfg[dbg]} == true ]]; then
			ncat -l -U "$socket" -c src/server.sh -k &
		else
			ncat -l -U "$socket" -c src/server.sh -k 2>> /dev/null &
		fi
		socat TCP-LISTEN:${cfg[port]},fork,bind=${cfg[ip]} UNIX-CLIENT:$socket &
		echo "[HTTP] listening on ${cfg[ip]}:${cfg[port]} through '$socket'"
	fi

	if [[ ${cfg[ssl]} == true ]]; then
		echo "[SSL] listening on port ${cfg[ip]}:${cfg[ssl_port]}"
		if [[ ${cfg[dbg]} == true ]]; then
			ncat -l ${cfg[ip]} ${cfg[ssl_port]} -c src/server.sh -k --ssl $([[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]] && echo "--ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]}") &
		else
			ncat -l ${cfg[ip]} ${cfg[ssl_port]} -c src/server.sh -k --ssl $([[ ${cfg[ssl_key]} != '' && ${cfg[ssl_cert]} != '' ]] && echo "--ssl-cert ${cfg[ssl_cert]} --ssl-key ${cfg[ssl_key]}") 2>> /dev/null &
		fi
	fi
fi

wait
