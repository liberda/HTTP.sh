#!/bin/bash

server_output() {
	prepare() {
		cat <<"EOF" > app/webroot/meow.shs
#!/bin/bash
echo meow
EOF
	}

	tst() {
		curl -s localhost:1337/meow.shs
	}

	match="meow"
}

server_get_param() {
	prepare() {
		cat <<"EOF" > app/webroot/meow.shs
#!/bin/bash
echo "${get_data[meow]}"
EOF
	}

	tst() {
		curl -s "localhost:1337/meow.shs?meow=nyaa"
	}

	match="nyaa"
}

server_get_random() {
	prepare() {
		cat <<"EOF" > app/webroot/meow.shs
#!/bin/bash
echo "${get_data[meow]}"
EOF
	}

	tst() {
		curl -s "localhost:1337/meow.shs?meow=nyaa"
	}

	match="nyaa"
}

server_post_param() {
	prepare() {
		cat <<"EOF" > app/webroot/meow.shs
#!/bin/bash
echo "${post_data[meow]}"
EOF
	}
	
	tst() {
		curl -s "localhost:1337/meow.shs" -d 'meow=nyaa'
	}

	match="nyaa"
}

server_res_header() {
	tst() {
		curl -s -I localhost:1337
	}

	match_sub="HTTP.sh"
}

server_res_header_custom() {
	prepare() {
		cat <<"EOF" > app/webroot/meow.shs
#!/bin/bash
header "meow: a custom header!"
EOF
	}

	tst() {
		curl -s -v localhost:1337/meow.shs 2>&1
	}

	match_sub="a custom header!"
}

server_req_header() {
	prepare() {
		cat <<"EOF" > app/webroot/meow.shs
#!/bin/bash
echo "${headers[meow]}"
EOF
	}
	
	tst() {
		curl -s "localhost:1337/meow.shs" -H 'meow: nyaa'
	}

	match="nyaa"
}

server_req_header_case() {
	tst() {
		curl -s "localhost:1337/meow.shs" -H 'Meow: nyaa'
	}

	match="nyaa"
}

server_req_header_dup() {
	tst() {
		curl -s "localhost:1337/meow.shs" -H 'Meow: nyaa' -H 'mEow: asdf'
	}
	# TODO: maybe we should return 400 when we detect sth like this?

	match="asdf"
}

server_req_header_invalid() {
	tst() {
		# we have to trick curl into sending an invalid header for us
		curl -s "localhost:1337/meow.shs" -H $'a:\nasdf asdf asdf asdf' -H "meow: asdf"
	}

	match_not="asdf"
}

server_req_header_special_value() {
	rand="$(cat /dev/urandom | cut -c 1-10 | head -n1 | sed -E 's/[\r\0]//')"

	tst() {
		# this needs some more polish, we sometimes confuse curl xD
		curl -s "localhost:1337/meow.shs" -H "meow: $rand"
	}

	match="$rand"
}

server_req_header_special_name() {
	rand="$(cat /dev/urandom | cut -c 1-10 | head -n1 | sed -E 's/[\r\0]//')"
	prepare() {
		cat <<EOF > app/webroot/meow.shs
#!/bin/bash
rand="\$(xxd -p -r <<< "$(echo "$rand" | xxd -p)")"
echo "\${headers["\${rand,,}"]}" # normalize to lowercase
EOF
	}
	
	tst() {
		curl -s "localhost:1337/meow.shs" -H "$rand: nyaa"
	}

	cleanup() {
		# *sigh* we need a better way to do this tbh
		rm app/webroot/meow.shs
	}

	match="nyaa"
}

subtest_list=(
	server_output
	server_get_param
	server_post_param

	server_res_header
	server_res_header_custom

	server_req_header
	server_req_header_case
	server_req_header_dup
	server_req_header_invalid
	server_req_header_special_value
	server_req_header_special_name
)
