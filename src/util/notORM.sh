#!/bin/bash
if [[ ! "$1" ]]; then
	echo "usage: $0 $HTTPSH_SCRIPTNAME <action> [params]

Action can be one of:
  dump <store> - dump the contents of a notORM store"
	exit 1
elif [[ "$1" == dump ]]; then
	x() { declare -p data; }
	data_iter "$2" { } x
fi
