#!/usr/bin/env bash
# account.sh - account and session mgmt
# TODO: add stricter argument checks for all the funcs

# registers a new user.
# first two params are strings; third is a reference to an array with
# optional extra data (email, OTP...)
#
# [extra=()] register(username, password)
function register() {
	if [[ ! "$1" || ! "$2" ]]; then
		reason="User/password empty!"
		return 1
	fi
	local username=$(url_decode "$1")
	unset IFS

	data_get secret/users.dat "$username"
	if [[ $? != 2 && $? != 4 ]]; then # entry not found / file not found
		reason="This user already exists!"
		return 1
	fi

	local salt=$(dd if=/dev/urandom bs=16 count=1 status=none | xxd -p)

	_password_hash "$2" "$salt"

	local out=("$username" "$hash" "$salt" "" "${extra[@]}")
	data_add secret/users.dat out

	_new_session "$username"

	set_cookie_permanent "sh_session" "${session[2]}"
	set_cookie_permanent "username" "$username"

	unset hash
}

# login(username, password, [forever]) -> [res]
function login() {
	if [[ ! "$1" || ! "$2" ]]; then
		reason="User/password empty!"
		return 1
	fi

	local username=$(url_decode "$1")
	[[ "$3" ]] && local forever=true
	unset IFS

	if ! data_get secret/users.dat "$username" 0 user; then
		reason="Bad credentials"
		return 1
	fi

	_password_hash "$2" "${user[2]}"

	if [[ "$hash" == "${user[1]}" ]]; then
		_new_session "$username" "$forever"

		if [[ "$forever" == true ]]; then
			set_cookie_permanent "sh_session" "${session[2]}"
			set_cookie_permanent "username" "$username"
		else
			set_cookie "sh_session" "${session[2]}"
			set_cookie "username" "$username"
		fi

		declare -ga res=("${user[@]:4}")

		unset hash
		return 0
	else
		remove_cookie "sh_session"
		remove_cookie "username"
		reason="Bad credentials"

		unset hash
		return 1
	fi
}

# login_simple(base64)
function login_simple() {

	local data=$(base64 -d <<< "$3")
	local password=$(sed -E 's/^(.*)\://' <<< "$data")
	local login=$(sed -E 's/\:(.*)$//' <<< "$data")

	if [[ ! "$password" || ! "$login" ]]; then
		return 1
	fi

	data_get secret/users.dat "$login" 0 user

	_password_hash "$password" "${user[2]}"

	if [[ "$hash" == "${user[1]}" ]]; then
		r[authorized]=true
	else 
		r[authorized]=false
	fi

	unset hash
}

# logout()
function logout() {
	if [[ "${cookies[sh_session]}" ]]; then
		data_yeet secret/sessions.dat "${cookies[sh_session]}" 2
	fi
	remove_cookie "sh_session"
	remove_cookie "username"
}

# session_verify(session) -> [res]
function session_verify() {
	[[ ! "$1" ]] && return 1
	unset IFS
	local session
	local user

	if data_get secret/sessions.dat "$1" 2 session; then
		if data_get secret/users.dat "${session[0]}" 0 user; then # double-check if tables agree
			declare -ga res=("${user[@]:4}")
			return 0
		fi
	fi
	return 1
}

# session_get_username(session)
function session_get_username() {
	[[ ! "$1" ]] && return 1
	unset IFS
	local session

	if data_get secret/sessions.dat "$1" 2 session; then
		if data_get secret/users.dat "${session[0]}" 0 user; then # double-check if tables agree
			echo "${user[0]}"
			return 0
		fi
	fi
	return 1
}

# THIS FUNCTION IS DANGEROUS
# delete_account(username)
function delete_account() {
  [[ ! "$1" ]] && return 1
  data_yeet secret/users.dat "$1"
}

# user_reset_password(username, token, new_password)
user_reset_password() {
	[[ ! "$1" ]] && return 1 # sensitive function, so we're checking all three
	[[ ! "$2" ]] && return 1 # there's probably a better way,
	[[ ! "$3" ]] && return 1 # but i don't care.

	local user
	if data_get secret/users.dat "$1" 0 user; then

		if [[ "$2" == "${user[3]}" ]]; then
			_password_hash "$3" "${user[2]}"
			user[1]="$hash"
			user[3]=''

			data_replace secret/users.dat "$1" user

			session_purge "$1"

			unset hash token
			return 0
		fi
	fi
	return 1
}

# user_change_password(username, old_password, new_password) -> $?, ${user[@]}
user_change_password() {
	[[ ! "$1" ]] && return 1
	[[ ! "$2" ]] && return 1
	[[ ! "$3" ]] && return 1
	if data_get secret/users.dat "$1" 0 user; then

		_password_hash "$2" "${user[2]}"

		if [[ "$hash" == "${user[1]}" ]]; then
			_password_hash "$3" "${user[2]}"
			[[ ! "$hash" ]] && return
			user[1]="$hash"
			user[3]=''
			data_replace secret/users.dat "$1" user

			session_purge "$1"

			unset hash token
			return 0
		fi
	fi

	unset hash
	return 1
}

# user_gen_reset_token(username) -> $?, $token, ${user[@]}
user_gen_reset_token() {
	[[ ! "$1" ]] && return 1
	
	if data_get secret/users.dat "$1" 0 user; then
		user[3]="$(dd if=/dev/urandom bs=20 count=1 status=none | xxd -p)"
		data_replace secret/users.dat "$1" user
		token="${user[3]}"
	else
		return 1
	fi
}

# logs out ALL sessions for user
#
# session_purge(username)
session_purge() {
	data_yeet secret/sessions.dat "$1"
}

# _new_session(username, forever) -> $session
_new_session() {
	[[ ! "$1" ]] && return 1
	[[ "$2" == true ]] && local forever=true || local forever=false
	session=("$1" "$(date '+%s')" "$(dd if=/dev/urandom bs=24 count=1 status=none | xxd -p)" "$forever")
	data_add secret/sessions.dat session
}

_password_hash() {
	[[ ! "$1" ]] && return 1
	[[ ! "$2" ]] && return 1

	if [[ "${cfg[hash]}" == "argon2id" ]]; then
		hash="$(echo -n "$1" | argon2 "$2" -id -e)"
	else
		hash=$(echo -n $1$2 | sha256sum | cut -c 1-64)
	fi
}
