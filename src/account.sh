#!/usr/bin/env bash
# account.sh - account and session mgmt

# registers a new user.
# first two params are strings; third is a reference to an array with
# optional extra data (email, OTP...)
#
# register(username, password, [extra])
function register() {
	local username=$(url_decode "$1")
	unset IFS

	data_get secret/users.dat "$username"
	if [[ $? != 2 && $? != 4 ]]; then # entry not found / file not found
		reason="This user already exists!"
		return 1		
	fi
	
	if [[ "${cfg[hash]}" == "argon2id" ]]; then
		local salt=$(dd if=/dev/urandom bs=256 count=1 | sha1sum | cut -c 1-16)
		local token=$(dd if=/dev/urandom bs=32 count=1 | sha1sum | cut -c 1-40)
		local hash="$(echo -n "$2" | argon2 "$salt" -id -e)"
	else
		local salt=$(dd if=/dev/urandom bs=256 count=1 | sha1sum | cut -c 1-16)
		local token=$(dd if=/dev/urandom bs=32 count=1 | sha1sum | cut -c 1-40)
		local hash=$(echo -n $2$salt | sha256sum | cut -c 1-64)
	fi
	
	set_cookie_permanent "sh_session" "$token"
	set_cookie_permanent "username" "$username"

	out=("$username" "$hash" "$salt" "$token" "${extra[@]}")
	data_add secret/users.dat out
}

# login(username, password) -> [res]
function login() {
	local username=$(url_decode "$1")
	unset IFS

	if ! data_get secret/users.dat "$username" 0 user; then
		reason="Bad credentials"
		return 1
	fi

	if [[ "${cfg[hash]}" == "argon2id" ]]; then
		hash="$(echo -n "$2" | argon2 "${user[2]}" -id -e)"
	else
		hash="$(echo -n $2${user[2]} | sha256sum | cut -c 1-64 )"
	fi
	
	if [[ "$hash" == "${user[1]}" ]]; then
		set_cookie_permanent "sh_session" "${user[3]}"
		set_cookie_permanent "username" "$username"

		declare -ga res=("${user[@]:4}")
		
		return 0
	else
		remove_cookie "sh_session"
		remove_cookie "username"
		reason="Bad credentials"
		return 1
	fi
}

# login_simple(base64)
function login_simple() {
	local data=$(base64 -d <<< "$3")
	local password=$(sed -E 's/^(.*)\://' <<< "$data")
	local login=$(sed -E 's/\:(.*)$//' <<< "$data")

	data_get secret/users.dat "$login" 0 user

	if [[ "${cfg[hash]}" == "argon2id" ]]; then
		hash="$(echo -n "$password" | argon2 "${user[2]}" -id -e)"
	else
		hash="$(echo -n $password${user[2]} | sha256sum | cut -c 1-64 )"
	fi
	
	if [[ "$hash" == "${user[1]}" ]]; then
		r[authorized]=true
	else 
		r[authorized]=false
	fi
}

# logout()
function logout() {
	remove_cookie "sh_session"
	remove_cookie "username"
}

# session_verify(session) -> [res]
function session_verify() {
	[[ "$1" == '' ]] && return 1
	unset IFS

	if data_get secret/users.dat "$1" 3; then
		declare -ga res=("${user[@]:4}")
		return 0
	fi
	return 1
}

# session_get_username(session)
function session_get_username() {
	[[ "$1" == "" ]] && return 1
	unset IFS

	if data_get secret/users.dat "$1" 3 user; then
		echo "${user[0]}"
		return 0
	fi
	return 1
}

# THIS FUNCTION IS DANGEROUS
# delete_account(username)
function delete_account() {
  [[ "$1" == "" ]] && return 1
  data_yeet secret/users.dat "$1"
}
