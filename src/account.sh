#!/usr/bin/env bash
# account.sh - account and session mgmt

# register(username, password)
function register() {
	local username=$(echo -ne $(sed -E "s/ /_/g;s/\:/\-/g;s/\%/\\x/g" <<< "$1"))

	IFS=$'\n'
	while read user; do
		IFS=: a=($user)
		if [[ "${a[0]}" == "$username" ]]; then
			reason="This user already exists!"
			return 1
		fi
	done < secret/users.dat
	unset IFS
	
	if [[ "${cfg[hash]}" == "argon2id" ]]; then
		local salt=$(dd if=/dev/urandom bs=256 count=1 | sha1sum | cut -c 1-16)
		local token=$(dd if=/dev/urandom bs=32 count=1 | sha1sum | cut -c 1-40)
		local hash="$(echo -n "$2" | argon2 "$salt" -id -e)"
	else
		local salt=$(dd if=/dev/urandom bs=256 count=1 | sha1sum | cut -c 1-16)
		local token=$(dd if=/dev/urandom bs=32 count=1 | sha1sum | cut -c 1-40)
		local hash=$(echo -n $2$salt | sha256sum | cut -c 1-64)
	fi
	
	set_cookie_permanent "sh_session" $token
	set_cookie_permanent "username" $username
	
	echo "$username:$hash:$salt:$token" >> secret/users.dat
}

# login(username, password) 
function login() {
	local username=$(echo -ne $(sed -E 's/%/\\x/g' <<< "$1"))
	IFS=$'\n'
	while read a; do
		IFS=: user=($a)
		if [[ "${user[0]}" == "$username" ]]; then
			break
		fi
	done < secret/users.dat
	if [[ "${user[0]}" == '' ]]; then
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

	IFS=$'\n'
	while read a; do
		IFS=':' user=($a)
		[[ ${user[0]} == "$login" ]] && break
	done < secret/users.dat
	unset IFS

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

# session_verify(session)
function session_verify() {
	[[ "$1" == '' ]] && return 1
	IFS=$'\n'
	while read user; do
		IFS=: a=($user)
		if [[ "${a[3]}" == "$1" ]]; then
			return 0
		fi
	done < secret/users.dat
	return 1
}

# session_get_username(session)
function session_get_username() {
	[[ "$1" == "" ]] && return 1

	IFS=$'\n'
	while read user; do
		IFS=':' a=($user)
		if [[ "${a[3]}" == "$1" ]]; then
			echo "${a[0]}"
			return 0
		fi
	done < secret/users.dat
	return 1
}

# THIS FUNCTION IS DANGEROUS
# delete_account(username)
function delete_account() {
  [[ "$1" == "" ]] && return 1
  sed -i "s/^$1:.*//;/^$/d" secret/users.dat
}
