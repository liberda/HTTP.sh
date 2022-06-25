#!/usr/bin/env bash
# template.sh - basic templating engine

# render(array, template_file)
function render() {
	local template="$(cat "$2" | sed 's/\&/�UwU�/g')"
	local -n ref=$1
	local tmp=$(mktemp)
	for key in ${!ref[@]}; do
		if [[ "$key" == "_"* ]]; then # iter mode
			local value=''
			subtemplate=$(mktemp)
			subtemplate_tmp=$(mktemp)
			echo "$template" | sed 's/\&/�UwU�/g' | grep "{{start $key}}" -A99999 | grep "{{end $key}}" -B99999 | tr '\n' $'\01' > "$subtemplate"

			echo 's'$'\02''\{\{start '"$key"'\}\}.*\{\{end '"$key"'\}\}'$'\02''\{\{'"$key"'\}\}'$'\02'';' >> "$tmp"

			local -n asdf=${ref[$key]}

			for j in ${!asdf[@]}; do
				local -n fdsa=_${asdf[$j]}

				for i in ${!fdsa[@]}; do
					echo 's'$'\02''\{\{.'"$i"'\}\}'$'\02'''"${fdsa[$i]}"''$'\02''g;' | tr '\n' $'\01' | sed 's/'$'\02'';'$'\01''/'$'\02'';/g' >> "$subtemplate_tmp"
				done

				echo 's'$'\02''\{\{start '"$key"'\}\}'$'\02'$'\02' >> "$subtemplate_tmp"
				echo 's'$'\02''\{\{end '"$key"'\}\}'$'\02'$'\02' >> "$subtemplate_tmp"
				
				value+="$(cat "$subtemplate" | tr '\n' $'\01' | sed -E -f "$subtemplate_tmp" | tr $'\01' '\n')"
				rm "$subtemplate_tmp"
			done

			echo 's'$'\02''\{\{'"$key"'\}\}'$'\02'''"$value"''$'\02'';' >> "$tmp"
			rm "$subtemplate"
		elif [[ "${ref[$key]}" != "" ]]; then
			local value="$(html_encode "${ref[$key]}" | sed -E 's/\&/�UwU�/g')"
			echo 's'$'\02''\{\{\.'"$key"'\}\}'$'\02'''"$value"''$'\02''g;' >> "$tmp"
		else
			echo 's'$'\02''\{\{\.'"$key"'\}\}'$'\02'$'\02''g;' >> "$tmp"
		fi
	done

	cat "$tmp" | tr '\n' $'\01' | sed 's/'$'\02'';'$'\01''/'$'\02'';/g' > "${tmp}_"
	template="$(tr '\n' $'\01' <<< "$template" | sed -E -f "${tmp}_" | tr $'\01' '\n')"
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
		fi
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
	declare -n nested_ref=$2
	declare -g -A _$nested_id
	
	# poor man's array copy
	for i in ${!nested_ref[@]}; do
		declare -g -A _$nested_id[$i]="${nested_ref[$i]}"
	done
	
	local -n ref=$1
	ref+=("$nested_id")
}

# nested_get(ref, i)
function nested_get() {
	local -n ref=$1
	declare -g -n res=_${ref[$2]}
}
