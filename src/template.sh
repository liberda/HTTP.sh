#!/bin/bash
# template.sh - basic templating engine

# render(array, template_file)
function render() {
	local template="$(cat "$2")"
	local -n ref=$1
	for key in ${!ref[@]}; do
		local value="$(html_encode "${ref[$key]}" | sed -E 's/\&/�UwU�/g')"
		template="$(sed -E 's/\{\{\.'"$key"'\}\}/'"$value"'/g' <<< "$template")"
	done

	sed -E 's/�UwU�/\&/g' <<< "$template"
}

# render_unsafe(array, template_file)
function render_unsafe() {
	local template="$(cat "$2")"
	local -n ref=$1
	for key in ${!ref[@]}; do
		local value="$(xxd -ps <<< "${ref[$key]}" | tr -d '\n' | sed -E 's/.{2}/\\x&/g')"
		template="$(sed -E 's/\{\{\.'"$key"'\}\}/'"$value"'/g' <<< "$template")"
	done

	echo "$template"
}
