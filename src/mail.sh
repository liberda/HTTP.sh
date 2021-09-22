#!/usr/bin/env bash
# mail.sh - basic SMTP handler

# mailgen(from, to, subject, msg)
function mailgen() {
	if [[ "$sender_name" != "" ]]; then
		echo "From: $sender_name <$1>"
	else
		echo "From: $1"
	fi
	echo "To: $2 
Subject: $3

$4"
}

# mailsend(to, subject, msg)
function mailsend() {
	tmp="$(mktemp)"
	sender_name="$sender_name" mailgen "${cfg[mail]}" "$1" "$2" "$3" > "$tmp"

	curl \
		$([[ "${cfg[mail_ignore_bad_cert]}" == true ]] && printf -- "-k") \
		$([[ "${cfg[mail_ssl]}" == true ]] && printf -- "smtps://${cfg[mail_server]}") \
		$([[ "${cfg[mail_ssl]}" != true ]] && printf -- "smtp://${cfg[mail_server]}") \
		--mail-from "${cfg[mail]}" \
		--mail-rcpt "$1" \
		--upload-file "$tmp" \
		--user "${cfg[mail]}:${cfg[mail_password]}"

	rm "$tmp"
}
