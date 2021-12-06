#!/bin/bash
# todo: 
# - dependencies.optional  dependencies.required
# - set namespace to '.'


function pack() {
	echo "function __main() {"
	cat http.sh
	echo "}"

	echo "function __account() {"
	cat src/account.sh
	echo "}"

	echo "function __mail() {"
	cat src/mail.sh
	echo "}"

	echo "function __mime() {"
	cat src/mime.sh
	echo "}"

	echo "function __misc() {"
	cat src/misc.sh
	echo "}"

	echo "function __route() {"
	cat src/route.sh
	echo "}"

	echo "function __server() {"
	cat src/server.sh
	echo "}"

	echo "function __template() {"
	cat src/template.sh
	echo "}"

	echo "function __worker() {"
	cat src/worker.sh
	echo "}"

	#echo "function __res_101 {"
	#cat src/response/101.sh
	#echo "}"

	echo "function __res_200() {"
	cat src/response/200.sh
	echo "}"

	echo "function __res_401() {"
	cat src/response/401.sh
	echo "}"

	echo "function __res_403() {"
	cat src/response/403.sh
	echo "}"

	echo "function __res_404() {"
	cat src/response/404.sh
	echo "}"

	echo "function __res_listing() {"
	cat src/response/listing.sh
	echo "}"

	echo "function __res_proxy() {"
	cat src/response/proxy.sh
	echo "}"

	echo "function __template_head() {"
	cat templates/head.sh
	echo "}"

	#echo "function __ws() {"
	#cat src/ws.sh
	#echo "}"
	echo '[[ "$1" == "server_int" ]] && __server
	[[ "$1" == "debug" ]] && __main debug
	[[ "$1" == "init" ]] && __main init
	[[ "$1" == "" ]] && __main'
}

pack | grep -v "packer-exclude" \
	 | sed -E  's@source "*src/response/@__res_@g;
				s@source "*src/@__@;
				s@__.*@&MaeIsCuteUwU@;
				s@\.sh"*MaeIsCuteUwU@@;
				s@source "*templates/head.sh@__template_head@;
				s@MaeIsCuteUwU@@g;
				s@exit .*@return@;
				s@-c src/server.sh@-c "$0 server_int"@g'
