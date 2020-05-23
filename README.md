# HTTP.sh
Node.js, but `| sed s/Node/HTTP/;s/js/sh/`.

Launch with `./http.sh`. Does not need root priviliges ~~- in fact, DO NOT run it as superuser~~ unless you're running it on ports lower than 1024. If you're running on 80 and 443, superuser is more or less mandatory, but THIS MAY BE UNSAFE.

To prevent running malicious scripts, by default only scripts with extension `.shs` can be run by the server, but this can be changed in the config. Also, cfg[index] ignores this. SHS stands for Shell Server.

Originally made for Junction Stupidhack 2020; Created by @redsPL, @selfisekai and @ptrcnull.

## Dependencies

- Bash or 100% compatible shell
- [Ncat](https://nmap.org/ncat)
- pkill
- mktemp
- dd (for accounts, multipart/form-data and websockets)
- sha1sum, sha256sum (for accounts and simple auth)
- curl (for some demos)

## Known faults

- can't change the HTTP status code from Shell Server scripts. This could theoretically be done with custom vhost configs and some `if` statements, but this would be a rather nasty solution to that problem.
- `$post_multipart` doesn't keep original names - could be fixed by parsing individual headers from the multipart request instead of skipping them all

## Directory structure (incomplete)
- config
	- master.sh: main config file, loaded with every request
	- localhost:1337: example vhost file, loaded if `Host: ...` equals its name
- src
	- server source files and modules (e.g. `ws.sh`)
	- response
		- files corresponding to specific HTTP status codes
		- listing.sh (code 210) is actually HTTP 200, but triggered in a directory with autoindex turned on and without a valid `index.shs` file
- templates
	- section templates go here
- webroot
	- place your files **here**
- secret
	- users/passwords go here
- storage
	- random data storage for shs apps

## Variables that we think are cool!

- $post_data - array, contains data from urlencoded POSTs
- $post_multipart - array, contains URIs to uploaded files from multipart/form-data POSTs
- $get_data - array, contains data from GETs
- $cfg - array, contains config values (from master.sh and vhost configs)
- $r - array, contains data generated from the request - URI, URL and that kinda stuff.
