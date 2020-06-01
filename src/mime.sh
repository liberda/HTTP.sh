#!/bin/bash

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
	local file=$@
	local mime=$(file --mime-type -b $file)
	if [[ $file == *".htm" || $file == *".html" ]]; then
		content_type="text/html"
		return 0
	elif [[ $file == *".shs" || $file == *".py" || $file == *".php" ]]; then
		content_type=""
		return 0
	elif [[ $file == *".css" ]]; then
		content_type="text/css"
	elif [[ $mime == "text/"* ]]; then
		content_type="text/plain"
	else
		content_type="$mime"
	fi
}
