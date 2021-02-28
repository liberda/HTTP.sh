#!/bin/bash
# template.sh - basic templating engine

# render(array, template_file)
function render() {
	local template="$(cat "$2")"
	local -n ref=$1
	local tmp=$(mktemp)
	for key in ${!ref[@]}; do
		local value="$(html_encode "${ref[$key]}" | sed -E 's/\&/�UwU�/g')"
		echo 's/\{\{\.'"$key"'\}\}/'"$value"'/g' >> "$tmp"
	done
	template="$(sed -E -f "$tmp" <<< "$template")"
	sed -E 's/�UwU�/\&/g' <<< "$template"
	rm "$tmp"
}

# render_unsafe(array, template_file)
function render_unsafe() {
	local template="$(cat "$2")"
	local -n ref=$1
	local tmp=$(mktemp)
	for key in ${!ref[@]}; do
		local value="$(xxd -ps <<< "${ref[$key]}" | tr -d '\n' | sed -E 's/.{2}/\\x&/g')"
		echo 's/\{\{\.'"$key"'\}\}/'"$value"'/g' >> "$tmp"
	done

	sed -E -f "$tmp" <<< "$template"
	rm "$tmp"
}
