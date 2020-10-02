# HTTP.sh
Node.js, but `| sed s/Node/HTTP/;s/js/sh/`.

Launch with `./http.sh`. Does not need root priviliges ~~- in fact, DO NOT run it as superuser~~ unless you're running it on ports lower than 1024. If you're running on 80 and 443, superuser is more or less mandatory, but THIS MAY BE UNSAFE.

To prevent running malicious scripts, by default only scripts with extension `.shs` can be run by the server, but this can be changed in the config. Also, cfg[index] ignores this. SHS stands for Shell Server.

Originally made for Junction Stupidhack 2020; Created by [sdomi](https://sakamoto.pl/), [selfisekai](https://selfisekai.rocks/) and [ptrcnull](https://ptrcnull.me/).

## Quick Start

If you want to build a new webapp from scratch:

```
./http.sh init
./http.sh
```

If you're setting up HTTP.sh for an existing application:

```
git clone https://git.sakamoto.pl/laudom/ocw/ app # example repo :P
./http.sh
```

## Dependencies

- Bash or 100% compatible shell
- [Ncat](https://nmap.org/ncat)
- pkill
- mktemp
- jq (probably not needed just yet, but it will be in 1.0)
- dd (for accounts, multipart/form-data and websockets)
- sha1sum, sha256sum, base64 (for accounts and simple auth)
- curl (for some demos)

## Known faults

- can't change the HTTP status code from Shell Server scripts. This could theoretically be done with custom vhost configs and some `if` statements, but this would be a rather nasty solution to that problem.
- `$post_multipart` doesn't keep original names - could be fixed by parsing individual headers from the multipart request instead of skipping them all

## Directory structure (incomplete)
- app (or any other namespace name! - check cfg[namespace])
	- webroot/ - place your files **here**
	- workers/ - workers live here
	- config.sh
- config
	- master.sh - main config file, loaded with every request
	- localhost:1337 - example vhost file, loaded if `Host: ...` equals its name
- src
	- server source files and modules (e.g. `ws.sh`)
	- response
		- files corresponding to specific HTTP status codes
		- listing.sh (code 210) is actually HTTP 200, but triggered in a directory with autoindex turned on and without a valid `index.shs` file
- templates - section templates go here
- secret - users, passwords and other Seecret data should be stored here
- storage - random data storage for your webapp

## Variables that we think are cool!

![](https://f.sakamoto.pl/d6584c01-1c48-42b9-935b-d9a89af4e071file_101.jpg)

- $post_data - array, contains data from urlencoded POSTs
- $post_multipart - array, contains URIs to uploaded files from multipart/form-data POSTs
- $get_data - array, contains data from GETs
- $cfg - array, contains config values (from master.sh and vhost configs)
- $r - array, contains data generated from the request - URI, URL and that kinda stuff.
