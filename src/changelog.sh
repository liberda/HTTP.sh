#!/bin/bash
# changelog.sh - functions for showing the changelog and warning about breaking changes

# Warn about breaking changes between versions.
# returns 1 if there are any breaking changes.
#
# check_ver(version_new, version_old) -> $breaking, $?
check_ver() {
	local from to n=9999999 line
	[[ "$1" == "" ]] && from=' ' || from="^$1"
	[[ "$2" == "" ]] && to=' ' || to="^$2"

	# if a version isn't referenced, just check all versions
	[[ "$(grep "$to$" CHANGELOG)" == "" ]] && to=' '

	while read -r line; do
		if [[ "$line" == "BREAKING"* ]]; then
			while read -r line && [[ "$line" != '' ]]; do
				breaking+="$line"$'\n'
			done
		fi
	done < <(grep -B$n "$to" CHANGELOG | grep -A$n "$from" | head -n -1)

	[[ ! "$breaking" ]] && return 0
	return 1
}
