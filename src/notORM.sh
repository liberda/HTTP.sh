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

repeat() {
	local IFS=$'\n'
	[[ "$1" -gt 0 ]] && printf -- "$2%.0s" $(seq 1 $1)
}

# adds a flat `array` to the `store`.
# a store can be any file, as long as we have r/w access to it and the
# adjacent directory.
#
# this function will create some helper files if they don't exist. those
# shouldn't be removed, as other functions may use them for data mangling.
#
# data_add(store, array)
data_add() {
	[[ ! -v "$2" ]] && return 1
	local -n ref="$2"
	[[ ! -f "$1" ]] && echo "${#ref[@]}" > "${1}.cols"
	local res=
	local IFS=$'\n'

	for i in "${ref[@]}"; do
		res+="$(echo -n "$i" | tr -d '\01\02\03' | tr '\n' '\02')"$delim
	done

	echo "$res" >> "$1" # TODO: some locking
}

# get one entry from store, filtering by search. exit after first result.
# by default uses the 0th column. override with optional `column`.
# returns the data to $res. override with optional `res`
#
# data_get(store, search, [column], [res]) -> $res / ${!4}
data_get() {
	[[ ! "$2" ]] && return 1
	[[ ! -f "$1" ]] && return 4
	local column=${3:-0}
	local -n ref=${4:-res}
	local IFS=$'\n'

	while read line; do
		local IFS=$delim
		ref=($(tr '\02' '\n' <<< "$line"))
		[[ "${ref[$column]}" == "$2" ]] && return 0
	done < "$1"

	return 2
}

# run `callback` on all entries from `store` that match `search`.
# by default uses the 0th column. override with optional `column`
#
# data_iter(store, search, callback, [column]) -> $data
data_iter() {
	[[ ! "$3" ]] && return 1
	local column=${4:-0}
	local IFS=$'\n'

	while read line; do
		local IFS=$delim
		data=($(tr '\02' '\n' <<< "$line"))
		[[ "${data[$column]}" == "$2" || ! "$2" ]] && "$3"
	done < "$1"
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
	
	if [[ $column == 0 ]]; then
		local expr="s$ctrl^$(_sed_sanitize "$2")(${delim}.*)$ctrl$(_sed_sanitize "$3")\1$ctrl"
	else
		local expr="s$ctrl^($(repeat $column ".*$delim"))$(_sed_sanitize "$2")($delim$(repeat $(( $(cat "${1}.cols") - column - 1 )) ".*$delim"))"'$'"$ctrl\1$(_sed_sanitize "$3")\2$ctrl"
	fi

	sed -E -i "$expr" "$1"
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
	local column=${4:-0}
	local -n ref="$3"
	local output=
	local IFS=' '
	
	for i in "${ref[@]}"; do
		output+="$(echo -n "$i" | tr -d '\01\02\03' | tr '\n' '\02')$delim"
	done
	
	if [[ $column == 0 ]]; then
		local expr="s$ctrl^$(_sed_sanitize "$2")${delim}.*$ctrl$(_sed_sanitize_array "$output")$ctrl"
	else
		local expr="s$ctrl^$(repeat $column ".*$delim")$(_sed_sanitize "$2")$delim$(repeat $(( $(cat "${1}.cols") - column - 1 )) ".*$delim")"'$'"$ctrl$(_sed_sanitize_array "$output")$ctrl"
	fi

	sed -E -i "$expr" "$1"
}

# deletes entries from the `store` using `search`.
# by default uses the 0th column. override with optional `column`
#
# data_yeet(store, search, [column])
data_yeet() {
	[[ ! "$2" ]] && return 1
	[[ ! -f "$1" ]] && return 4
	local column=${3:-0}
	local IFS=' '

	if [[ $column == 0 ]]; then
		local expr="/^$(_sed_sanitize "$2")${delim}.*/d"
	else
		local expr="/^$(repeat $column ".*$delim")$(_sed_sanitize "$2")$delim$(repeat $(( $(cat "${1}.cols") - column - 1 )) ".*$delim")"'$'"/d"
	fi

	sed -E -i "$expr" "$1"
}

_sed_sanitize() {
	echo -n "$1" | tr -d '\01\02\03' | tr '\n' '\02' | xxd -p | tr -d '\n' | sed -E 's/../\\x&/g'	
}

_sed_sanitize_array() {
	echo -n "$1" | xxd -p | tr -d '\n' | sed -E 's/../\\x&/g'	
}

