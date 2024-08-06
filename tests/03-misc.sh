#!/bin/bash

misc_html_escape_basic() {
	prepare() {
		source src/misc.sh
	}
	tst() {
		html_encode "$value"
	}
	value="meow"
	match="meow"
}

misc_html_escape_special() {
	value="<script>"
	match_not="<"
}

misc_html_escape_apos() {
	value="<img src='asdf'>"
	match_not="'"
}

misc_html_escape_quot() {
	value='<img src="meow">'
	match_not='"'
}

# ---

misc_url_encode() {
	tst() {
		url_encode "$value"
	}
	value="nyaa"
	match=""
}

misc_url_encode_special01() {
	value="%%"
	match="%25%25"
}

misc_url_encode_special02() {
	value="&"
	match_not="&"
}

misc_url_encode_special03() {
	value="?asdf=meow&nyaa="
	match_not="?"
}

misc_url_encode_url() {
	value="https://example.org/?nyaa=meow"
	# i promise we'll get a better impl of this at some point xD
	match="%68%74%74%70%73%3a%2f%2f%65%78%61%6d%70%6c%65%2e%6f%72%67%2f%3f%6e%79%61%61%3d%6d%65%6f%77" 
}

# ---

misc_url_decode_encode() {
	tst() {
		url_decode "$(url_encode "$value")"
	}
	value="https://example.org/?nyaa=meow&as=df"
	match="$value"
}

# ---

misc_url_decode01() {
	tst() {
		url_decode "$value"
	}
	value='%25'
	match='%'
}

misc_url_decode02() {
	value='%2525'
	match='%25'
}

subtest_list=(
	misc_html_escape_basic
	misc_html_escape_special
	misc_html_escape_apos
	misc_html_escape_quot

	misc_url_encode
	misc_url_encode_special01
	misc_url_encode_special02
	misc_url_encode_special03
	misc_url_encode_url

	misc_url_decode_encode

	misc_url_decode01
	misc_url_decode02
)
