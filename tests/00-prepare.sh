#!/bin/bash

prepare() {
	[[ ! -d app ]] && ./http.sh init
	./http.sh >/dev/null &
}

tst() {
	for i in {1..10}; do
		if [[ "$(ss -tulnap | grep LISTEN | grep 1337)" ]]; then
			return 0
		fi
		sleep 0.5
	done

	return 255
}
