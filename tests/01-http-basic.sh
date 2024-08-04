#!/bin/bash

test_server_header() {
	tst() {
		curl -s -I localhost:1337
	}

	match_sub="HTTP.sh"
}

test_server_output() {
	prepare() {
		cat <<"EOF" > app/webroot/meow.shs
#!/bin/bash
echo meow
EOF
	}
	
	cleanup() {
		rm app/webroot/meow.shs
	}

	tst() {
		curl -s localhost:1337/meow.shs
	}

	match="meow"
}

test_server_get_param() {
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

test_server_post_param() {
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


subtest_list=(
	test_server_header
	test_server_output
	test_server_get_param
	test_server_post_param
)
