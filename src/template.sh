#!/usr/bin/env bash
# template.sh - basic templating engine

# render(array, template_file)
function render() {
	local template="$(cat "$2")"
	local -n ref=$1
	local tmp=$(mktemp)
	for key in ${!ref[@]}; do
		if [[ "$key" == "_"* ]]; then # iter mode
			local subtemplate=$(mktemp)
			grep "start $key" -A99999 | grep "end $key" -B99999 > "$subtemplate"
			local -n item_array=${ref[$key]}
			echo 's/{{start '"$key"'}}.*{{end '"$key"'}}/{{'"$key"'}}/' >> "$tmp"
			for (( i=0; i<${#item_array}; i++ )); do
				nested_get item_array $i
				for meow in ${!res[@]}; do
					local -n nyaa=${res[$meow]}
					# todo: unhtml_encode this?
					local value="$(html_encode "$(render nyaa "$subtemplate")" | sed -E 's/\&/�UwU�/g')"
					echo 's/{{'"${res[$meow]}"'}}/'"$value"'/' >> "$tmp"
					
				done
			done
			echo 's/\{\{'"$key"'\}\}/'"$value"'/g' >> "$tmp"
			rm "$subtemplate"
		elif [[ "${ref[$key]}" != "" ]]; then
			local value="$(html_encode "${ref[$key]}" | sed -E 's/\&/�UwU�/g')"
			echo 's/\{\{\.'"$key"'\}\}/'"$value"'/g' >> "$tmp"
		else
			echo 's/\{\{\.'"$key"'\}\}//g' >> "$tmp"
		fi
	done
	
	template="$(tr '\n' $'\01' <<< "$template" | sed -E -f "$tmp" | tr $'\01' '\n')"
	sed -E 's/�UwU�/\&/g' <<< "$template"
	rm "$tmp"
}

# render_unsafe(array, template_file)
function render_unsafe() {
	local template="$(cat "$2")"
	local -n ref=$1
	local tmp=$(mktemp)
	for key in ${!ref[@]}; do
		if [[ "$key" == "_"* ]]; then # iter mode
			# grep "start _test" -A99999 | grep "end _test" -B99999
			local -n item_array=${ref[$key]}
			local value
			for ((i = 0; i < ${#item_array[@]}; i++)); do
				value+="$(xxd -ps <<< "${item_array[$i]}" | tr -d '\n' | sed -E 's/../\\x&/g')"
			done
			echo 's/\{\{'"$key"'\}\}/'"$value"'/g' >> "$tmp"
		else
			local value="$(xxd -ps <<< "${ref[$key]}" | tr -d '\n' | sed -E 's/../\\x&/g')"
			echo 's/\{\{\.'"$key"'\}\}/'"$value"'/g' >> "$tmp"
	done

	sed -E -f "$tmp" <<< "$template"
	rm "$tmp"
}


# mmmm this should be a library because i am so much copying those later
# _nested_random
function _nested_random() {
	dd if=/dev/urandom bs=1 count=16 status=none | xxd -p
}

# nested_declare(ref)
function nested_declare() {
	declare -g -a $1
}

# nested_add(ref, array)
function nested_add() {
	local nested_id=$(_nested_random)
	declare -g -n _$nested_id=$2
	local -n ref=$1
	ref+=("$nested_id")
}

# nested_get(ref, i)
function nested_get() {
	local -n ref=$1
	declare -g -n res=_${ref[$2]}
}
