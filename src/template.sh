#!/usr/bin/env bash
# template.sh - basic templating engine

# nightmare fuel
# render(array, template_file, recurse)
function render() {
	if [[ "$3" != true ]]; then
		local template="$(tr -d $'\01'$'\02' < "$2" | sed 's/\&/�UwU�/g')"
	else
		local template="$(tr -d '$\02' < "$2" | sed -E 's/\\/\\\\/g')"
	fi
	local -n ref=$1
	local tmp=$(mktemp)

	local key
	IFS=$'\n'
	for key in ${!ref[@]}; do
		if [[ "$key" == "_"* ]]; then # iter mode
			local subtemplate=$(mktemp)
			echo "$template" | grep "{{start $key}}" -A99999 | grep "{{end $key}}" -B99999 | tr '\n' $'\01' > "$subtemplate"

			echo 's'$'\02''\{\{start '"$key"'\}\}.*\{\{end '"$key"'\}\}'$'\02''\{\{'"$key"'\}\}'$'\02'';' >> "$tmp"

			local -n asdf=${ref["$key"]}
			local j
			local value=''
			for j in ${!asdf[@]}; do
				local -n fdsa=_${asdf[$j]}

				value+="$(render fdsa "$subtemplate" true)"
			done
			value="$(tr -d '$\02' <<< "$value" | sed -E 's'$'\02''\{\{start '"$key"'\}\}'$'\02'$'\02'';s'$'\02''\{\{end '"$key"'\}\}'$'\02'$'\02')"

			echo 's'$'\02''\{\{'"$key"'\}\}'$'\02'''"$value"''$'\02'';' >> "$tmp"
			rm "$subtemplate"
		elif [[ "$key" == "@"* && "${ref["$key"]}" != '' ]]; then
			local value="$(tr -d $'\01\02' <<< "${ref["$key"]}" | sed -E 's/\&/�UwU�/g')"
			echo 's'$'\02''\{\{\'"$key"'\}\}'$'\02'''"$value"''$'\02''g;' >> "$tmp" #'
		elif [[ "$key" == '?'* ]]; then
			local _key="\\?${key/?/}"

			local subtemplate=$(mktemp)
			echo 's'$'\02''\{\{start '"$_key"'\}\}((.*)\{\{else '"$_key"'\}\}.*\{\{end '"$_key"'\}\}|(.*)\{\{end '"$_key"'\}\})'$'\02''\2\3'$'\02'';' >> "$subtemplate"

			# TODO: check if this is needed?
			# the code below makes sure to resolve the conditional blocks
			# *before* anything else. I can't think of *why* this is needed
			# right now, but I definitely had a reason in this. Question is, what reason.
			
			cat <<< $(cat "$subtemplate" "$tmp") > "$tmp" # call that cat abuse

			rm "$subtemplate"
		elif [[ "${ref["$key"]}" != "" ]]; then
			echo "VALUE: ${ref["$key"]}" > /dev/stderr
			if [[ "$3" != true ]]; then
				local value="$(html_encode <<< "${ref["$key"]}" | tr -d $'\02' | sed -E 's/\&/�UwU�/g')"
			else
				local value="$(echo -n "${ref["$key"]}" | tr -d $'\01'$'\02' | tr $'\n' $'\01' | sed -E 's/\\\\/�OwO�/g;s/\\//g;s/�OwO�/\\/g' | html_encode | sed -E 's/\&/�UwU�/g')"
			fi
			echo 's'$'\02''\{\{\.'"$key"'\}\}'$'\02'''"$value"''$'\02''g;' >> "$tmp"
		else
			echo 's'$'\02''\{\{\.'"$key"'\}\}'$'\02'$'\02''g;' >> "$tmp"
		fi
	done
	unset IFS

	# process file includes;
	# achtung: even though this is *after* the main loop, it actually executes sed reaplces *before* it;
	# recursion is currently unsupported here, i feel like it may break things?
	if [[ "$template" == *'{{#'* && "$3" != true ]]; then
		local subtemplate=$(mktemp)
		while read key; do 
			# below check prevents the loop loading itself as a template.
			# this is possibly not enough to prevent all recursions, but
			# i see it as a last-ditch measure. so it'll do here.
			if [[ "$file" == "$2" ]]; then
				echo 's'$'\02''\{\{\#'"$key"'\}\}'$'\02''I cowardly refuse to endlessly recurse\!'$'\02''g;' >> "$subtemplate"
			elif [[ -f "$key" ]]; then
				echo 's'$'\02''\{\{\#'"$key"'\}\}'$'\02'"$(tr -d $'\01'$'\02' < "$key" | tr $'\n' $'\01' | sed 's/\&/�UwU�/g')"$'\02''g;' >> "$subtemplate"
				_template_find_special_uri "$(cat "$key")"
			fi
		done <<< "$(grep -Poh '{{#.*?}}' <<< "$template" | sed 's/{{#//;s/}}$//')"

		cat <<< $(cat "$subtemplate" "$tmp") > "$tmp"
		rm "$subtemplate"
	fi

	_template_find_special_uri "$template"
	_template_gen_special_uri >> "$tmp"

	if [[ "$3" != true ]]; then # are we recursing?
		cat "$tmp" | tr '\n' $'\01' | sed -E 's/'$'\02'';'$'\01''/'$'\02'';/g;s/'$'\02''g;'$'\01''/'$'\02''g;/g' > "${tmp}_"
		
		echo 's/\{\{start \?([a-zA-Z0-9_-]*[^}])\}\}(.*\{\{else \?\1\}\}(.*)\{\{end \?\1\}\}|.*\{\{end \?\1\}\})/\3/g' >> "${tmp}_"
		template="$(tr '\n' $'\01' <<< "$template" | sed -E -f "${tmp}_" | tr $'\01' '\n')"
		sed -E 's/�UwU�/\&/g' <<< "$template"
		rm "$tmp" "${tmp}_"
	else
		tr '\n' $'\01' <<< "$template" | sed -E -f "$tmp" | tr $'\01' '\n'
		rm "$tmp"
	fi
}

_template_uri_list=()
# internal function that finds all occurences of the special `{{-uri-N}}` tag.
# here to also make it run on subtemplates
#
# _template_find_special_uri(tpl_string)
_template_find_special_uri() {
	local IFS=$'\n'
	local line
	if [[ "$1" == *'{{-uri'* ]]; then
		while read line; do
			_template_uri_list+=("${line//[^0-9]}")
		done <<< "$(grep -Poh '{{-uri-[0-9]*}}' <<< "$1")"
	fi
}

# internal function that takes the output from _template_find_special_uri and
# transforms it into sed exprs
#
# _template_gen_special_uri() -> stdout
_template_gen_special_uri() {
	local IFS=$'\n'
	local num
	local uri
	# {{-uri-<num>}}, where num is amount of slashed parts to include
	sort <<< ${_template_uri_list[*]} | uniq | while read num; do
		uri="$(grep -Poh '^(/.*?){'"$((num+1))"'}' <<< "${r[url_clean]}/")"
		echo 's'$'\02''\{\{-uri-'"$num"'\}\}'$'\02'"$uri"$'\02''g;'
	done
	# for replacing plain {{-uri}} without a number
	echo 's'$'\02''\{\{-uri\}\}'$'\02'"${r[url_clean]}"$'\02''g;'
}

# render_unsafe(array, template_file)
function render_unsafe() {
	local template="$(cat "$2")"
	local -n ref=$1
	local tmp=$(mktemp)
	for key in ${!ref[@]}; do
		if [[ "$key" == "_"* ]]; then # iter mode
			# grep "start _test" -A99999 | grep "end _test" -B99999
			local -n item_array=${ref["$key"]}
			local value
			for ((_i = 0; _i < ${#item_array[@]}; _i++)); do
				value+="$(xxd -p <<< "${item_array[$_i]}" | tr -d '\n' | sed -E 's/../\\x&/g')"
			done
			echo 's/\{\{'"$key"'\}\}/'"$value"'/g' >> "$tmp"
		else
			local value="$(xxd -p <<< "${ref["$key"]}" | tr -d '\n' | sed -E 's/../\\x&/g')"
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
	declare -g -A _$nested_id

	local a
	a="$(declare -p "$2")"
	# pain
	eval "${a/ $2=/ -g _$nested_id=}"
	
	local -n ref=$1
	ref+=("$nested_id")
}

# nested_get(ref, i)
function nested_get() {
	local -n ref=$1
	declare -g -n res=_${ref["$2"]}
}
