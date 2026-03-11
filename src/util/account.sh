#!/bin/bash
if [[ ! "$1" ]]; then
	echo "usage: $0 $HTTPSH_SCRIPTNAME <action> [params]

Action can be one of:
  register <user> - will ask for password on stdin. Accepts ${extra[@]} for
                    additional fields.
  delete <user>   - simple user yeet
  reset <user>    - reset password; will ask for a new one on stdin
  logout <user>   - logout all sessions of a user 
  "
	exit 1
elif [[ "$1" == register ]]; then
	read -s -p 'Password: ' pass
	if [[ ! "$pass" ]]; then
		echo "Password cannot be empty" >&2
		exit 1
	fi
	register "$2" "$pass"

elif [[ "$1" == delete ]]; then
	delete_account "$2"

elif [[ "$1" == reset ]]; then
	if user_gen_reset_token "$2"; then
		read -p "New password: " -s pass
		user_reset_password "$2" "$token" "$pass"
	fi

elif [[ "$1" == logout ]]; then
	session_purge "$2"

else
	echo "Unknown action: $2" >&2
	exit 1

fi
