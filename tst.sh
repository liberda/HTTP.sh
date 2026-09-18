#!/usr/bin/env bash
trap ctrl_c INT
ctrl_c() {
	pkill -P $$
	echo -e "Interrupted and cleaned up."
	return 255
}

_defaults() {
	match=""
	match_begin=""
	match_end=""
	match_sub=""

	tst() {
		echo "dummy test! please set me up properly" > /dev/stderr
		exit 1
	}

	prepare() {
		:
	}

	cleanup () {
		:
	}
}

source app/localcfg.sh
_defaults

on_error() {
	on_error_default
}

on_error_mail() {
    on_error_default_mail
}

on_success() {
	on_success_default
}

on_success_mail() {
    on_success_default_mail
}

on_success_default() {
	echo "OK: $test_name"
	(( ok_count++ ))
	return 0
}

on_success_default_mail() {
    echo "OK: $test_name (mailer)"
	(( ok_count++ ))
	return 0
}

on_error_default() {
	echo "FAIL: $test_name"
	echo "(res: $res)"
	(( fail_count++ ))
	return 0
}

on_error_default_mail() {
    echo "FAIL: $test_name (mailer)"
	echo "(res: $mail_res)"
	(( fail_count++ ))
	return 0
}

on_fatal() {
	echo "FATAL: $test_name"
	_final_cleanup
	exit 1
}

IFS=$'\n'
for i in "$@"; do
	if [[ ! -f "$i" ]]; then
		echo "ENOENT: $i"
		echo -e "$0 - basic test framework\n\nusage: $0 <test> [test] [...]"
		exit 1
	fi
done
unset IFS

ok_count=0
fail_count=0

_a() {
	local _success=true
	[[ "$res_code" == 255 ]] && on_fatal
	
	[[ "$res_code" != 0 ]] && _success=false
	[[ "$match" ]] && [[ "$res" != "$match" ]] && _success=false
	[[ "$match_sub" ]] && [[ "$res" != *"$match_sub"* ]] && _success=false
	[[ "$match_begin" ]] && [[ "$res" != "$match_begin"* ]] && _success=false
	[[ "$match_end" ]] && [[ "$res" != *"$match_end" ]] && _success=false
	[[ "$match_not" ]] && [[ "$res" == *"$match_not"* ]] && _success=false

	if [[ "$_success" == true ]]; then
		on_success
	else
		on_error
	fi

	unset match match_sub match_begin match_end match_not mail_res match_mail
	prepare() { :; }
}

_final_cleanup() {
	# handle spawned processes
	for i in $(jobs -p); do
		pkill -P $i
	done
	if [[ "$(jobs -p)" != '' ]]; then
		sleep 1
		for i in $(jobs -p); do
			pkill -9 -P $i
		done
	fi
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

    if [[ -e "$mailer_testing_out" ]]; then
        rm "$mailer_testing_out"
    fi

	_defaults
done

_final_cleanup

echo -e "\nTesting done!
OK:   $ok_count
FAIL: $fail_count"

if [[ "$fail_count" -gt 0 ]]; then
    exit 1
fi
