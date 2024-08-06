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

subtest_list=(
	tpl_basic
	tpl_basic_specialchars
	tpl_basic_newline
)
