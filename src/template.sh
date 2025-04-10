#!/usr/bin/env bash
# template.sh - basic templating engine

# nightmare fuel
# render(array, template_file, recurse)
function render() {
	local _tpl_newline=$'\01'
	local _tpl_ctrl=$'\02'

	if [[ "$3" != true ]]; then
		local template="$(tr -d "${_tpl_newline}${_tpl_ctrl}" < "$2" | sed 's/\&/�UwU�/g')"
	else
		local template="$(tr -d "${_tpl_ctrl}" < "$2" | sed -E 's/\\/\\\\/g')"
	fi
	local buf=
	local garbage="$template"$'\n'
	local -n ref=$1

	# process file includes;
	# recursion is currently unsupported here, i feel like it may break things?
	if [[ "$template" == *'{{#'* && "$3" != true ]]; then
		local subtemplate=
		while read key; do 
			# below check prevents the loop loading itself as a template.
			# this is possibly not enough to prevent all recursions, but
			# i see it as a last-ditch measure. so it'll do here.
			if [[ "$file" == "$2" ]]; then
				subtemplate+="s${_tpl_ctrl}\{\{\#$key\}\}${_tpl_ctrl}I cowardly refuse to endlessly recurse\!${_tpl_ctrl}g;"
			elif [[ -f "$key" ]]; then
				local input="$(tr -d "${_tpl_ctrl}${_tpl_newline}" < "$key" | sed 's/\&/�UwU�/g')"
				garbage+="$input"$'\n'
				input="$(tr $'\n' "${_tpl_newline}" <<< "$input")" # for another hack
				subtemplate+="s${_tpl_ctrl}\{\{\#$key\}\}${_tpl_ctrl}${input}${_tpl_ctrl};"
				_template_find_special_uri "$(cat "$key")"
			fi
		done <<< "$(grep -Poh '{{#\K(.*?)(?=}})' <<< "$template")"

		buf+="${subtemplate}"
	fi

	# process special set statements
	if [[ "$garbage" == *'{{-set-'* ]]; then
		while read key; do
			ref["?$key"]=_
		done <<< "$(grep -Poh '{{-set-\K(.*?)(?=}})' <<< "$garbage" | sed 's/[^a-z0-9_-]//g')"
	fi

	local key
	IFS=$'\n'
	for key in ${!ref[@]}; do
		if [[ "$key" == "_"* ]]; then # iter mode
			# THE MOST EVIL OF ALL HACKS:
			# we're scraping a subtemplate from our main template.
			# HOWEVER: this fails on included templates, because they're not real.
			# this means that iterators can't work on included templates
			#
			# workaround? collect all includes, concatenate them all together and just.
			# use that pile of garbage here along with the real template. it works!
			local subtemplate="$(grep "{{start $key}}" -A99999 <<< "$garbage" | grep "{{end $key}}" -B99999 | tr '\n' "${_tpl_newline}")"
			local -n asdf=${ref["$key"]}
			local j
			local value=''
			local _index=0
			for j in ${!asdf[@]}; do
				local -n fdsa=_${asdf[$j]}
				fdsa["-index"]="$_index"
				value+="$(render fdsa /dev/stdin true <<< "$subtemplate")"
				(( _index++ ))
			done

			buf+="s${_tpl_ctrl}\{\{start $key\}\}.*\{\{end $key\}\}${_tpl_ctrl}\{\{$key\}\}${_tpl_ctrl};s${_tpl_ctrl}\{\{$key\}\}${_tpl_ctrl}$(tr -d "${_tpl_ctrl}" <<< "$value" | sed "s${_tpl_ctrl}{{start $key}}${_tpl_ctrl}${_tpl_ctrl};s${_tpl_ctrl}{{end $key}}${_tpl_ctrl}${_tpl_ctrl}")${_tpl_ctrl};"
			unset "$subtemplate"
		elif [[ "$key" == "@"* && "${ref["$key"]}" != '' ]]; then
			local value="$(tr -d "${_tpl_ctrl}${_tpl_newline}" <<< "${ref["$key"]}" | sed -E 's/\&/�UwU�/g')"
			buf+="s${_tpl_ctrl}\{\{$key\}\}${_tpl_ctrl}${value}${_tpl_ctrl}g;"
		elif [[ "$key" == "-index" && "$3" == true ]]; then # foreach index mode
			buf+="s${_tpl_ctrl}\{\{\-index\}\}${_tpl_ctrl}${_index}${_tpl_ctrl}g;"
		elif [[ "$key" == "+"* ]]; then # date mode
			if [[ ! "${ref["$key"]}" ]]; then
				# special case: if the date is empty,
				# make the output empty too
				buf+="s${_tpl_ctrl}\{\{\\$key\}\}${_tpl_ctrl}${_tpl_ctrl}g;"
			else
				local value
				printf -v value "%(${cfg[template_date_format]})T" "${ref["$key"]}"
				buf+="s${_tpl_ctrl}\{\{\\$key\}\}${_tpl_ctrl}${value}${_tpl_ctrl};"
			fi
		elif [[ "$key" == '?'* ]]; then
			local _key="\\?${key/?/}"

			buf+="s${_tpl_ctrl}"'\{\{start '"$_key"'\}\}((.*)\{\{else '"$_key"'\}\}.*\{\{end '"$_key"'\}\}|(.*)\{\{end '"$_key"'\}\})'"${_tpl_ctrl}"'\2\3'"${_tpl_ctrl};"

		elif [[ "${ref["$key"]}" != "" ]]; then
			if [[ "$3" != true ]]; then
				local value="$(html_encode <<< "${ref["$key"]}" | tr -d "${_tpl_ctrl}" | sed -E 's/\&/�UwU�/g')"
			else
				local value="$(echo -n "${ref["$key"]}" | tr -d "${_tpl_ctrl}${_tpl_newline}" | tr $'\n' "${_tpl_newline}" | sed -E 's/\\\\/�OwO�/g;s/\\//g;s/�OwO�/\\/g' | html_encode | sed -E 's/\&/�UwU�/g')"
			fi
			buf+="s${_tpl_ctrl}\{\{\.$key\}\}${_tpl_ctrl}${value}${_tpl_ctrl}g;"
		else
			buf+="s${_tpl_ctrl}\{\{\.$key\}\}${_tpl_ctrl}${_tpl_ctrl}g;"
		fi
	done
	unset IFS

	_template_find_special_uri "$template"
	buf+="$(_template_gen_special_uri)"

	if [[ "$3" != true ]]; then # are we recursing?
		tr '\n' "${_tpl_newline}" <<< "$template" | sed -E -f <(
			tr '\n' "${_tpl_newline}" <<< "$buf" | sed $'s/\02;\01/\02;/g;s/\02g;\01/\02g;/g' # i'm sorry what is this sed replace??
			echo -n 's/\{\{start \?([a-zA-Z0-9_-]*[^}])\}\}(.*\{\{else \?\1\}\}(.*)\{\{end \?\1\}\}|.*\{\{end \?\1\}\})/\3/g'
		) | tr "${_tpl_newline}" '\n' | sed -E 's/�UwU�/\&/g'
	else
		tr '\n' "${_tpl_newline}" <<< "$template" | sed -E -f <(echo -n "$buf") | tr "${_tpl_newline}" '\n'
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

# nested_declare(ref)
function nested_declare() {
	declare -g -a $1
}

# nested_add(ref, array)
function nested_add() {
	local nested_id=template_internal_$EPOCHSECONDS$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM
	local -n ref=$1
	local -n arr_ref=$2

	local IFS=
	: "${arr_ref[@]@A}"
	declare -g -${arr_ref@a} _$nested_id="${_#*=}"
	
	ref+=("$nested_id")
}

# nested_get(ref, i)
function nested_get() {
	local -n ref=$1
	declare -g -n res=_${ref["$2"]}
}
