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

	cleanup() {
		rm "$store"
	}
}

notORM_add_autoincrement() {
	prepare() {
		a=("meow" "nyaa")
		data_add "$store" a true
		data_add "$store" a true
		a=("nyaa" "...")
		data_add "$store" a true
	}

	tst() {
		data_get "$store" { 2 } { "..." 2 } || return 1
		echo -n "${res[1]}"
	}

	match="nyaa"

	cleanup() {
		rm "$store"
	}
}

notORM_mapping() {
	tst() {
		data_mapping aoeu.dat id name whatever

		[[ "${_notORM_map[aoeu.dat,id]}" != 0 ]] && return 1
		[[ "${_notORM_map[aoeu.dat,name]}" != 1 ]] && return 1
		[[ "${_notORM_map[aoeu.dat,whatever]}" != 2 ]] && return 1
		return 0
	}
	cleanup() {
		unset _notORM_map _notORM_revmap
		declare -gA _notORM_map
		declare -gA _notORM_revmap
	}
}

notORM_mapping_duplicate() {
	tst() {
		! data_mapping asdf.dat meow meow
	}
}

# try to match a column by name
notORM_mapping_retrieve() {
	prepare() {
		data_mapping storage/asdf.dat id name occupation
		a=(0 meow nyaa)
		data_add storage/asdf.dat a
	}

	tst() {
		data_get storage/asdf.dat { meow name }
	}

	cleanup() {
		:
	}
}

# match a column by name, and check if output got expanded
# uses the data from above
notORM_mapping_retrieve_revmap() {
	tst() {
		declare -gA res
		data_get storage/asdf.dat { meow name }

		[[ "${res[occupation]}" == "nyaa" ]] || return 1
	}
}

# check if cfg[notORM_always_asssoc] works
notORM_mapping_always() {
	tst() {
		cfg[notORM_always_asssoc]=true
		data_get storage/asdf.dat { meow name } assoc_test

		[[ "${assoc_test[occupation]}" == "nyaa" ]] || return 1
	}
}

# test the fallback in case of a missing map
notORM_mapping_missing() {
	tst() {
		unset _notORM_revmap _notORM_map
		declare -gA _notORM_revmap
		declare -gA _notORM_map
		
		declare -gA res
		data_get storage/asdf.dat { meow 1 }

		[[ "${res[2]}" == nyaa ]] || return 1
	}
}

notORM_mapping_iter() {
	tst() {
		cb() {
			[[ "${adata[occupation]}" == nyaa ]] &&	success=true
		}
		data_iter storage/asdf.dat { meow name } cb true

		[[ "$success" == true ]] || return 1
	}
}

notORM_mapping_add() {
	tst() {
		declare -A items
		items[id]=1
		items[name]="spezi"
		items[occupation]="mmmmm... lecker"

		data_add storage/asdf.dat items || return $?
		
		declare -A out
		data_get storage/asdf.dat { spezi name } out

		[[ "${out[occupation]}" == *"lecker" ]] || return 1
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
	notORM_add_autoincrement

	notORM_mapping
	notORM_mapping_duplicate
	notORM_mapping_retrieve
	notORM_mapping_retrieve_revmap
	notORM_mapping_always
	notORM_mapping_missing
	notORM_mapping_iter
	notORM_mapping_add
)
