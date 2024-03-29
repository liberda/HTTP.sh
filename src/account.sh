#!/usr/bin/env bash
# account.sh - account and session mgmt


# register(username, password)
function register() {
	local username=$(echo -ne $(sed -E "s/ /_/g;s/\:/\-/g;s/\%/\\x/g" <<< "$1"))

	if [[ $(grep "$username:" secret/users.dat) != '' ]]; then
		reason="This user already exists!"
		return 1
	fi
	
	local salt=$(dd if=/dev/urandom bs=256 count=1 | sha1sum | cut -c 1-16)
	local hash=$(echo -n $2$salt | sha256sum | cut -c 1-64)
	local token=$(dd if=/dev/urandom bs=32 count=1 | sha1sum | cut -c 1-40)
	set_cookie_permanent "sh_session" $token
	set_cookie_permanent "username" $username
	
	echo "$username:$hash:$salt:$token" >> secret/users.dat
}

# login(username, password) 
function login() {
	local username=$(echo -ne $(sed -E 's/%/\\x/g' <<< "$1"))
	IFS=':'
	local user=($(grep -P "$username:" secret/users.dat))
	unset IFS
	if [[ $(echo -n $2${user[2]} | sha256sum | cut -c 1-64 ) == "${user[1]}" ]]; then
		set_cookie_permanent "sh_session" "${user[3]}"
		set_cookie_permanent "username" "$username"
		return 0
	else
		remove_cookie "sh_session"
		remove_cookie "username"
		reason="Invalid credentials!!11"
		return 1
	fi
}

# login_simple(base64)
function login_simple() {
	local data=$(base64 -d <<< "$3")
	local password=$(sed -E 's/^(.*)\://' <<< "$data")
	local login=$(sed -E 's/\:(.*)$//' <<< "$data")
	
	IFS=':'
	local user=($(grep "$login:" secret/users.dat))
	unset IFS
	if [[ $(echo -n $password${user[2]} | sha256sum | cut -c 1-64 ) == ${user[1]} ]]; then
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
	if [[ $(grep ":$1" secret/users.dat) != '' && $1 != '' ]]; then
		return 0
	else
		return 1
	fi
}

# session_get_username(session)
function session_get_username() {
	[[ "$1" == "" ]] && return

	IFS=':'
	local data=($(grep ":$1$" secret/users.dat))
	unset IFS
	echo ${data[0]}
}

# THIS FUNCTION IS DANGEROUS
# delete_account(username)
function delete_account() {
  [[ "$1" == "" ]] && return
  sed -i "s/^$1:.*//;/^$/d" secret/users.dat
}
