#!/bin/bash
## notORM.sh - clearly, not an ORM.
# basic interface for saving semi-arbitrary data organized in "tables".

## limitations:
# - only for strings (we trim some bytes; see `reserved values` below)
# - currently only supports saving to CSV-with-extra-steps

## function return values:
#
# 0 - success
# 1 - general failure
# 2 - entry not found
# 3 - locked, try again later
# 4 - file not found

## data reserved values:
#
# \x00 - bash yeets it out of existence
# \x01 - delimeter
# \x02 - newline
# \x03 - control chr for sed
delim=$'\01'
newline=$'\02'
ctrl=$'\03'

# TODO: proper locking
# TODO: matching more than one column 

repeat() {
	local IFS=$'\n'
	[[ "$1" -gt 0 ]] && printf -- "$2%.0s" $(seq 1 $1)
}

shopt -s expand_aliases
# internal. parses the `{ }` syntax, starting with 2nd arg.
# alias, not a function, because we want to modify the argv of the parent
# _data_parse_pairs(_, { search, column }, [{ search2, column2 }], ...) -> ${search[@]}, ${column[@]}
alias _data_parse_pairs='
	local search=()
	local column=()

	while shift; do # "shebang reference?" ~ mei
		[[ "$1" != "{" ]] && break # yes, we need to match this twice
		if [[ "$2" != "}" || "$3" == "}" || "$4" == "}" ]]; then # make sure we dont want to match the bracket
			search+=("$2")
		else # empty search - just match ANY record
			search+=("")
			column+=(0)
			shift 2
			break
		fi
		if [[ "$3" != "}" ]]; then
			column+=("$3")
			[[ "$4" != "}" ]] && return 1 # we accept only values in pairs
			shift 3
		else
			column+=(0)
			shift 2
			if [[ "$2" != "{" ]]; then
				shift
				break
			fi
		fi
	done
'

# internal function. take search and column, generate a sed matching expr from them
# data_gen_expr() -> $expr
_data_gen_expr() {
	# we need the pairs sorted due to how the sed expr generation works
	local IFS=$'\01\n'
	local i
	sorted=($(for (( i=0; i<${#search[@]}; i++ )); do
		echo "${column[i]}"$'\01'"${search[i]}"
	done | sort -n -t$'\01'))

	local last=0
	for (( i=0; i<${#sorted[@]}; i=i+2 )); do
		if [[ $((sorted[i] - last)) -le 1 ]]; then
			expr+="$(_sed_sanitize "${sorted[i+1]}")${delim}"
		else
			expr+="$(repeat $((sorted[i] - last)) ".*$delim")$(_sed_sanitize "${sorted[i+1]}")${delim}"
		fi
		last="${sorted[i]}"
	done
}

# adds a flat `array` to the `store`.
# a store can be any file, as long as we have r/w access to it and the
# adjacent directory.
#
# 3rd argument is optional, and will specify whether to insert an auto-increment
# ID column. False by default; Setting to true will cause an internal data_iter
# call. The inserted ID column is always the zeroeth one.
#
# this function will create some helper files if they don't exist. those
# shouldn't be removed, as other functions may use them for data mangling.
#
# data_add(store, array, [numbered])
data_add() {
	[[ ! -v "$2" ]] && return 1
	local -n ref="$2"
	local res=
	local IFS=$'\n'

	if [[ ! -f "$1" ]]; then
		if [[ "$3" == true ]]; then
			res+="0$delim"
			echo "$((${#ref[@]}+1))" > "${1}.cols"
		else
			echo "${#ref[@]}" > "${1}.cols"
		fi
	elif [[ "$3" == true ]]; then
		local data
		data_iter "$1" { } : # get last element
		local id=$(( ${data[0]}+1 )) # returns 1 on non-int values
		
		res+="$id$delim"
	fi

	local i
	for i in "${ref[@]}"; do
		_trim_control "$i"
		res+="$tr$delim"
	done

	echo "$res" >> "$1" # TODO: some locking
}

# get one entry from store, filtering by search. exit after first result.
# by default uses the 0th column. override with optional `column`.
# returns the data to $res. override with optional `res`
#
# 2nd and 3rd arguments can be repeated, given you enclose each pair
# in curly braces. (e.g. `{ search } { search2 column2 }`)
#
# also can be used as `data_get store { } meow` to match all records 
#
# data_get(store, { search, [column] }, ... [res]]) -> $res / ${!-1}
# data_get(store, search, [column], [res]) -> $res / ${!4}
data_get() {
	[[ ! "$2" ]] && return 1
	[[ ! -f "$1" ]] && return 4
	local IFS=$'\n'
	local store="$1"

	if [[ "$2" == '{' ]]; then
		_data_parse_pairs
		local -n ref="${1:-res}"
	else # compat
		local search=("$2")
		local column=("${3:-0}")
		local -n ref=${4:-res}
	fi

	local line
	while read line; do
		IFS=$delim
		
		# LOAD-BEARING!!
		# without an intermediate variable, bash trims out empty
		# objects. expansions be damned
		local x="${line//$newline/$'\n'}"
		ref=($x)
		local i
		for (( i=0; i<${#search[@]}; i++ )); do
			if [[ "${ref[column[i]]}" != "${search[i]}" && "${search[i]}" ]]; then
				continue 2
			fi
		done
		return 0 # only reached if an entry matched all constraints
	done < "$store"

	unset ref
	return 2
}

# run `callback` on all entries from `store` that match `search`.
# by default uses the 0th column. override with optional `column`
#
# immediately exits with 255 if the callback function returned 255
# if there were no matches, returns 2
# if the store wasn't found, returns 4
#
# data_iter(store, { search, [column] }, ... callback) -> $data
# data_iter(store, search, callback, [column]) -> $data
data_iter() {
	[[ ! "$3" ]] && return 1
	[[ ! -f "$1" ]] && return 4
	local store="$1"
	local IFS=$'\n'
	local r=2

	if [[ "$2" == '{' ]]; then
		_data_parse_pairs
		local callback="$1"
	else # compat
		local callback="$3"
		local search=("$2")
		local column=("${4:-0}")
	fi

	while read line; do
		IFS=$delim
		
		# LOAD BEARING; see data_get
		local x="${line//$newline/$'\n'}"
		data=($x)
		IFS=
		local i
		for (( i=0; i<${#search[@]}; i++ )); do
			if [[ "${data[column[i]]}" != "${search[i]}" && "${search[i]}" ]]; then
				continue 2
			fi
		done
		"$callback" # only reached if an entry matched all constraints
		[[ $? == 255 ]] && return 255
		r=0
	done < "$store"

	return $r
}

# replace a value in `store` with `array`, filtering by `search`.
# by default uses the 0th column. override with optional `column`
#
# `value` is any string, which will directly replace `search`
#
# data_replace_value(store, search, value, [column])
data_replace_value() {
	[[ ! "$3" ]] && return 1
	[[ ! -f "$1" ]] && return 4
	local column=${4:-0}
	local IFS=' '

	# NOTE: sed in normal (not extended -E mode) requires `\(asdf\)` to make a match!
	if [[ $column == 0 ]]; then
		local expr="s$ctrl^$(_sed_sanitize "$2")\(${delim}.*\)$ctrl$(_sed_sanitize "$3")\1$ctrl"
	else
		local expr="s$ctrl^\($(repeat $column ".*$delim")\)$(_sed_sanitize "$2")\($delim$(repeat $(( $(cat "${1}.cols") - column - 1 )) ".*$delim")\)"'$'"$ctrl\1$(_sed_sanitize "$3")\2$ctrl"
	fi

	sed -i "$expr" "$1"
}

# replace an entire entry in `store` with `array`, filtering by `search`.
# by default uses the 0th column. override with optional `column`
#
# pass `array` without expanding (`arr`, not `$arr`).
#
# data_replace(store, search, array, [column])
data_replace() {
	[[ ! "$3" ]] && return 1
	[[ ! -f "$1" ]] && return 4
	local store="$1"
	local output=
	local tr
## currently broken
# 	if [[ "$2" == '{' ]]; then
# 		_data_parse_pairs
# 
# 		local -n ref="$1"
# 
# 		local expr
# 		_data_gen_expr
# 		expr="s$ctrl^${expr}.*$ctrl"
# 	else
		local column=${4:-0}
		local -n ref="$3"
		local IFS=' '

		if [[ $column == 0 ]]; then
			local expr="s$ctrl^$(_sed_sanitize "$2")${delim}.*$ctrl"
		else
			local expr="s$ctrl^$(repeat $column ".*$delim")$(_sed_sanitize "$2")$delim$(repeat $(( $(cat "${store}.cols") - column - 1 )) ".*$delim")"'$'"$ctrl"
		fi

	# fi
	local i
	for i in "${ref[@]}"; do
		_trim_control "$i"
		output+="$tr$delim"
	done

	expr+="$(_sed_sanitize_array "$output")$ctrl"
	sed -i "$expr" "$store"
}

# deletes entries from the `store` using `search`.
# by default uses the 0th column. override with optional `column`
#
# data_yeet(store, search, [column])
# data_yeet(store, { search, [column] }, ...)
data_yeet() {
	[[ ! "$2" ]] && return 1
	[[ ! -f "$1" ]] && return 4
	local store="$1"

	if [[ "$2" == '{' ]]; then
		_data_parse_pairs

		local expr
		_data_gen_expr
		expr="/^${expr}.*/d"
	else # compat
		local search="$2"
		local column="${3:-0}"
		local IFS=' '
		if [[ $column == 0 ]]; then
			local expr="/^$(_sed_sanitize "$2")${delim}.*/d"
		else
			local expr="/^$(repeat $column ".*$delim")$(_sed_sanitize "$2")$delim$(repeat $(( $(cat "${store}.cols") - column - 1 )) ".*$delim")"'$'"/d"
		fi
	fi

	sed -i "$expr" "$store"
}

_sed_sanitize() {
	_trim_control "$1"
	echo -n "$tr" | xxd -p | tr -d '\n' | sed 's/../\\x&/g'
}

_sed_sanitize_array() {
	echo -n "$1" | xxd -p | tr -d '\n' | sed 's/../\\x&/g'
}

# _trim_control(string) -> $tr
_trim_control() {
	tr="${1//$delim}"          # remove 0x01
	tr="${tr//$newline}"       # remove 0x02
	tr="${tr//$ctrl}"          # remove 0x03
	tr="${tr//$'\n'/$newline}" # \n -> 0x02
}

shopt -u expand_aliases # back to the default
