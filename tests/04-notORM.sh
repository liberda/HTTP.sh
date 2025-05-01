#!/bin/bash
store="storage/notORM-test.dat"

notORM_add_get() {
	prepare() {
		source src/notORM.sh
		rm "$store"
		
		a=("$value" 1 "$value_")
		data_add "$store" a
		for i in {2..16}; do
			a[1]=$i
			data_add "$store" a
		done
	}
	tst() {
		data_get "$store" { } || return $?
		echo "${res[0]}"
	}

	value="A quick brown fox jumped over the lazy dog"
	value_=$'meow?\n:3c'
	match="$value"
}

notORM_get_multiline() {
	tst() {
		data_get "$store" { }
		echo "${res[2]}"
	}
	match="$value_"
}

notORM_get_filter() {
	tst() {
		data_get "$store" { "2" 1 }
		return $?
	}
}

notORM_get_oldsyntax() {
	tst() {
		data_get "$store" 2 1 meow || return $?
		[[ "${meow[0]}" == "$value" ]] && return 0 || return 1
	}
}

notORM_yeet_oldsyntax() {
	tst() {
		data_yeet "$store" 1 1
		data_get "$store" 1 1
		if [[ $? == 2 ]]; then
			return 0
		fi
		return 1
	}
}

notORM_yeet() {
	tst() {
		data_yeet "$store" { 2 1 }
		data_get "$store" { 2 1 }
		if [[ $? == 2 ]]; then
			return 0
		fi
		return 1
	}
}

notORM_yeet_multiple_filters() {
	tst() {
		data_yeet "$store" { 3 1 } { "$value" }
		data_get "$store" { 3 1 }
		if [[ $? == 2 ]]; then
			return 0
		fi
		return 1
	}
}

notORM_replace_oldsyntax() {
	tst() {
		data_get "$store" { } out
		out[2]='meow!'
		data_replace "$store" 4 out 1 || return $?
		data_get "$store" 4 1 || return $?
		[[ "${res[@]}" == "${out[@]}" ]] && return 0 || return 1
	}
}

notORM_backslashes() {
	tst() {
		a=('\0meow')
		data_add "$store" a
		a=('awawa')
		data_add "$store" a

		# checks whether data didn't get mangled and can be retrieved
		data_get "$store" { '\0meow' } || return $?

		# tries to delete the entry, then checks if it got matched
		data_yeet "$store" { '\0meow' }
		data_get "$store" { '\0meow' }
		if [[ $? == 0 ]]; then
			return 1
		fi

		return 0
	}	
}

subtest_list=(
	notORM_add_get
	notORM_get_multiline
	notORM_get_filter
	notORM_get_oldsyntax
	notORM_yeet_oldsyntax
	notORM_yeet
	notORM_yeet_multiple_filters
	notORM_replace_oldsyntax
	notORM_backslashes
)
