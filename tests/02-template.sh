#!/bin/bash

tpl_basic() {
	prepare() {		
		source src/misc.sh
		source src/template.sh
	}
	tst() {
		declare -A meow
		meow[asdf]="$value"
		
		render meow <(echo "value: {{.asdf}}")
	}

	value="A quick brown fox jumped over the lazy dog"
	match="value: $value"
}

tpl_basic_specialchars() {
	value="&#$%^&*() <-- look at me go"
	match="value: $(html_encode "$value")"
}

tpl_basic_newline() {
	value=$'\n'a$'\n'
	match="value: $(html_encode "$value")"
}

tpl_date() {	
	tst() {
		declare -A cfg
		cfg[template_date_format]='%Y-%m-%d %H:%M:%S'

		declare -A meow
		meow[+asdf]="$value"
		
		render meow <(echo "value: {{+asdf}}")
	}

	value="1337"
	match="value: 1970-01-01 01:22:17"
}

tpl_date_empty() {
	value=""
	match="value: "
}

tpl_date_invalid() {
	value="gadjkghfdklh"
	match="value: 1970-01-01 01:00:00"
}

tpl_path_custom() {
	prepare() {
		declare -ga template_relative_paths=("/tmp/")

		tempfile="$(mktemp)" || return 1
	}

	tst() {
		declare -A meow
		render meow "$(basename "$tempfile")"
	}
}

tpl_path_inheritance() {
	prepare() {
		tempdir="$(mktemp -d)" || return 1
		declare -ga template_relative_paths=(
			"$tempdir"
			"/tmp/"
		)
	}
}

tpl_path_include() {
	prepare() {
		another_tempfile="$(mktemp)"
		echo "meow?" > "$another_tempfile"
		echo "{{#$(basename "$another_tempfile")}}" > "$tempfile"
	}

	match="meow?"

	cleanup() {
		rm -R "$tempdir"
		rm "$tempfile" "$another_tempfile"
	}
}


subtest_list=(
	tpl_basic
	tpl_basic_specialchars
	tpl_basic_newline

	tpl_date
	tpl_date_empty
	tpl_date_invalid

	tpl_path_custom
	tpl_path_inheritance
	tpl_path_include
)
