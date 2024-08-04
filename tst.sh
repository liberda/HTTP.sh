#!/bin/bash

tst() {
	echo "dummy test!"
}

match=""
match_begin=""
match_end=""
match_sub=""

prepare() {
	:
}

cleanup () {
	:
}

on_error() {
	on_error_default
}

on_success() {
	on_success_default
}

on_success_default() {
	echo "OK: $test_name"
	(( ok_count++ ))
	return 0 # surprisingly load-bearing
}

on_error_default() {
	echo "FAIL: $test_name"
	echo "(res: $res)"
	(( fail_count++ ))
	return 0
}

on_fatal() {
	echo "FATAL: $test_name"
	_final_cleanup
	exit 1
}

if [[ ! -f "$1" ]]; then
	echo -e "$0 - basic test framework\n\nusage: $0 <test> [test] [...]"
	exit 1
fi

ok_count=0
fail_count=0

_a() {
	[[ "$res_code" == 255 ]] && on_fatal
	if [[ "$match" ]]; then
		[[ "$res" == "$match" ]] && on_success || on_error
	elif [[ "$match_sub" ]]; then
		[[ "$res" == *"$match_sub"* ]] && on_success || on_error
	elif [[ "$match_begin" ]]; then
		[[ "$res" == "$match_begin"* ]] && on_success || on_error
	elif [[ "$match_end" ]]; then
		[[ "$res" == *"$match_end" ]] && on_success || on_error
	else
		[[ "$res_code" == 0 ]] && on_success || on_error
	fi
	unset match match_sub match_begin match_end
	prepare() { :; }
}

_final_cleanup() {
	# handle spawned processes
	for i in $(jobs -p); do
		pkill -P $i
	done
	sleep 2
	for i in $(jobs -p); do
		pkill -9 -P $i
	done
	pkill -P $$
}

for j in "$@"; do
	source "$j"
	if [[ "${#subtest_list[@]}" == 0 ]]; then
		test_name="$j"
		prepare
		res="$(tst)"
		res_code=$?
		cleanup
		_a
	else
		echo "--- $j ---"
		for i in "${subtest_list[@]}"; do
			test_name="$i"
			"$i"
			prepare
			res="$(tst)"
			res_code=$?
			cleanup
			_a
		done
	fi
done

_final_cleanup

echo -e "\n\nTesting done!
OK:   $ok_count
FAIL: $fail_count"
