#!/bin/bash
# mail.sh - basic SMTP handler

# mailgen(from, to, subject, msg)
function mailgen() {
	echo "From: $1
To: $2
Subject: $3

$4"
}

# mailsend(to, subject, msg)
function mailsend() {
	tmp="$(mktemp)"
	mailgen "${cfg[mail]}" "$1" "$2" "$3" > "$tmp"

	curl \
		$([[ ${cfg[mail_ignore_bad_cert]} == true ]] && printf -- "-k") \
		$([[ ${cfg[mail_ssl]} == true ]] && printf -- "--ssl") \
		"smtp://${cfg[mail_server]}" \
		--mail-from "${cfg[mail]}" \
		--mail-rcpt "$1" \
		--upload-file "$tmp" \
		--user "${cfg[mail]}:${cfg[mail_password]}"

	rm "$tmp"
}
