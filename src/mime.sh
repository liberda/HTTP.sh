#!/usr/bin/env bash

# mime.sh - determine what Content-Type should be passed on
#
# Common HTML files (.html/.htm) -> text/html
# Shell Server Scripts (.shs) -> leaves without any content type, TBD by the browser
# CSS files (.css) -> text/css
# Text files (mimetype starting with 'text/') -> text/plain (fixes XSS in pastebin)
# All else -> pass real mimetype
#
# For some reason, we now have PHP and Python support (issue #1).
# PHP (.php) -> no content-type
# Python (.py) -> no content-type

function get_mime() {
	local file="$@"
	if [[ -f "$file" ]]; then
		local mime="$(file --mime-type -b "$file")"
		if [[ $file == *".htm" || $file == *".html" || $mime == "text/html" ]]; then
			mimetype="text/html"
		elif [[ $file == *".shs" || $file == *".py" || $file == *".php" ]]; then
			mimetype=""
		elif [[ $file == *".css" ]]; then
			mimetype="text/css"
		elif [[ $mime == "text/"* && $mime != "text/xml" ]]; then
			mimetype="text/plain"
		else
			mimetype="$mime"
		fi
	else
		mimetype=""
	fi
}

