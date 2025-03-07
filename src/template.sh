#!/usr/bin/env bash
# template.sh - basic templating engine
_tpl_newline=$'\01'
_tpl_ctrl=$'\02'

# nightmare fuel
# render(array, template_file, recurse)
function render() {
	if [[ "$3" != true ]]; then
		local template="$(tr -d ${_tpl_newline}${_tpl_ctrl} < "$2" | sed 's/\&/�UwU�/g')"
	else
		local template="$(tr -d ${_tpl_ctrl} < "$2" | sed -E 's/\\/\\\\/g')"
	fi
	local -n ref=$1
	local tmp=$(mktemp)

	local key
	IFS=$'\n'
	for key in ${!ref[@]}; do
		if [[ "$key" == "_"* ]]; then # iter mode
			local subtemplate=$(mktemp)
			echo "$template" | grep "{{start $key}}" -A99999 | grep "{{end $key}}" -B99999 | tr '\n' "${_tpl_newline}" > "$subtemplate"

			echo "s${_tpl_ctrl}\{\{start $key\}\}.*\{\{end $key\}\}${_tpl_ctrl}\{\{$key\}\}${_tpl_ctrl};" >> "$tmp"

			local -n asdf=${ref["$key"]}
			local j
			local value=''
			for j in ${!asdf[@]}; do
				local -n fdsa=_${asdf[$j]}

				value+="$(render fdsa "$subtemplate" true)"
			done
			value="$(tr -d "${_tpl_ctrl}" <<< "$value" | sed -E "s${_tpl_ctrl}"'\{\{start '"$key"'\}\}'"${_tpl_ctrl}${_tpl_ctrl};s${_tpl_ctrl}"'\{\{end '"$key"'\}\}'"${_tpl_ctrl}${_tpl_ctrl}")"

			echo "s${_tpl_ctrl}\{\{$key\}\}${_tpl_ctrl}${value}${_tpl_ctrl};" >> "$tmp"
			rm "$subtemplate"
		elif [[ "$key" == "@"* && "${ref["$key"]}" != '' ]]; then
			local value="$(tr -d "${_tpl_ctrl}${_tpl_newline}" <<< "${ref["$key"]}" | sed -E 's/\&/�UwU�/g')"
			echo "s${_tpl_ctrl}\{\{$key\}\}${_tpl_ctrl}${value}${_tpl_ctrl}g;" >> "$tmp"
		elif [[ "$key" == "+"* ]]; then # date mode
			if [[ ! "${ref["$key"]}" ]]; then
				# special case: if the date is empty,
				# make the output empty too
				echo "s${_tpl_ctrl}\{\{\\$key\}\}${_tpl_ctrl}${_tpl_ctrl}g;" >> "$tmp"
			else
				local value
				printf -v value "%(${cfg[template_date_format]})T" "${ref["$key"]}"
				echo "s${_tpl_ctrl}\{\{\\$key\}\}${_tpl_ctrl}${value}${_tpl_ctrl};" >> "$tmp"
			fi
		elif [[ "$key" == '?'* ]]; then
			local _key="\\?${key/?/}"

			local subtemplate=$(mktemp)
			echo "s${_tpl_ctrl}"'\{\{start '"$_key"'\}\}((.*)\{\{else '"$_key"'\}\}.*\{\{end '"$_key"'\}\}|(.*)\{\{end '"$_key"'\}\})'"${_tpl_ctrl}"'\2\3'"${_tpl_ctrl};" >> "$subtemplate"

			# TODO: check if this is needed?
			# the code below makes sure to resolve the conditional blocks
			# *before* anything else. I can't think of *why* this is needed
			# right now, but I definitely had a reason in this. Question is, what reason.
			
			cat <<< $(cat "$subtemplate" "$tmp") > "$tmp" # call that cat abuse

			rm "$subtemplate"
		elif [[ "${ref["$key"]}" != "" ]]; then
			echo "VALUE: ${ref["$key"]}" > /dev/stderr
			if [[ "$3" != true ]]; then
				local value="$(html_encode <<< "${ref["$key"]}" | tr -d "${_tpl_ctrl}" | sed -E 's/\&/�UwU�/g')"
			else
				local value="$(echo -n "${ref["$key"]}" | tr -d "${_tpl_ctrl}${_tpl_newline}" | tr $'\n' "${_tpl_newline}" | sed -E 's/\\\\/�OwO�/g;s/\\//g;s/�OwO�/\\/g' | html_encode | sed -E 's/\&/�UwU�/g')"
			fi
			echo "s${_tpl_ctrl}\{\{\.$key\}\}${_tpl_ctrl}${value}${_tpl_ctrl}g;" >> "$tmp"
		else
			echo "s${_tpl_ctrl}\{\{\.$key\}\}${_tpl_ctrl}${_tpl_ctrl}g;" >> "$tmp"
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
				echo "s${_tpl_ctrl}\{\{\#$key\}\}${_tpl_ctrl}I cowardly refuse to endlessly recurse\!${_tpl_ctrl}g;" >> "$subtemplate"
			elif [[ -f "$key" ]]; then
				echo "s${_tpl_ctrl}\{\{\#$key\}\}${_tpl_ctrl}$(tr -d "${_tpl_ctrl}${_tpl_newline}" < "$key" | tr $'\n' "${_tpl_newline}" | sed 's/\&/�UwU�/g')${_tpl_ctrl};" >> "$subtemplate"
				_template_find_special_uri "$(cat "$key")"
			fi
		done <<< "$(grep -Poh '{{#.*?}}' <<< "$template" | sed 's/{{#//;s/}}$//')"

		cat <<< $(cat "$subtemplate" "$tmp") > "$tmp"
		rm "$subtemplate"
	fi

	_template_find_special_uri "$template"
	_template_gen_special_uri >> "$tmp"

	if [[ "$3" != true ]]; then # are we recursing?
		cat "$tmp" | tr '\n' "${_tpl_newline}" | sed -E $'s/\02;\01/\02;/g;s/\02g;\01/\02g;/g' > "${tmp}_" # i'm sorry what is this sed replace??
		
		echo 's/\{\{start \?([a-zA-Z0-9_-]*[^}])\}\}(.*\{\{else \?\1\}\}(.*)\{\{end \?\1\}\}|.*\{\{end \?\1\}\})/\3/g' >> "${tmp}_"
		template="$(tr '\n' ${_tpl_newline} <<< "$template" | sed -E -f "${tmp}_" | tr "${_tpl_newline}" '\n')"
		sed -E 's/�UwU�/\&/g' <<< "$template"
		rm "$tmp" "${tmp}_"
	else
		tr '\n' "${_tpl_newline}" <<< "$template" | sed -E -f "$tmp" | tr "${_tpl_newline}" '\n'
		rm "$tmp"
	fi

	[[ "$3" != true ]] && _template_uri_list=()
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
		echo "s${_tpl_ctrl}\{\{-uri-$num\}\}${_tpl_ctrl}${uri}${_tpl_ctrl}g;"
	done
	# for replacing plain {{-uri}} without a number
	echo "s${_tpl_ctrl}\{\{-uri\}\}${_tpl_ctrl}${r[url_clean]}${_tpl_ctrl}g;"
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
