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

subtest_list=(
	tpl_basic
	tpl_basic_specialchars
	tpl_basic_newline

	tpl_date
	tpl_date_empty
	tpl_date_invalid
)
