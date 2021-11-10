# HTTP.sh
Node.js, but `| sed 's/Node/HTTP/;s/js/sh/'`.

HTTP.sh is (by far) the most extensible attempt at creating a web framework in Bash, and (AFAIK) the only one that's actively maintained. Although I strive for code quality, this is still rather experimental and may contain bugs.

Originally made for Junction Stupidhack 2020; Created by [sdomi](https://sakamoto.pl/), [ptrcnull](https://ptrcnull.me/) and [selfisekai](https://selfisekai.rocks/).

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

We also support Docker! Both a Dockerfile and an example docker-compose.yml are included for your convenience. Containerizing your webapp is as easy as `docker-compose up -d`

## Dependencies

- Bash (4.x should work, but we'll need 5.0 soon)
- [Ncat](https://nmap.org/ncat), not openbsd-nc, not netcat, not nc
- socat (because the above is slightly broken)
- pkill
- mktemp
- jq (probably not needed just yet, but it will be in 1.0)
- dd (for accounts, multipart/form-data and websockets)
- sha1sum, sha256sum, base64 (for accounts and simple auth)
- curl (for some demos)

## Known faults

- can't change the HTTP status code from Shell Server scripts. This could theoretically be done with custom vhost configs and some `if` statements, but this would be a rather nasty solution to that problem.
- `$post_multipart` doesn't keep original names - could be fixed by parsing individual headers from the multipart request instead of skipping them all
- it won't ever throw a 500, thus it fails silently

## Directory structure
- ${cfg[namespace]} (`app` by default)
	- ${cfg[root]} (`webroot` by default) - public application root
	- workers/ - scripts that execute periodically live there (see examples)
	- views/ - for use with HTTP.sh router
	- config.sh - application-level config file
- config
	- master.sh - main server config file - loaded on boot and with every request
	- host:port - if a file matching the Host header is found, HTTP.sh will load it request-wide
- src
	- server source files and modules
	- response
		- files corresponding to specific HTTP status codes
		- listing.sh (code 210) is actually HTTP 200, but triggered in a directory with autoindex turned on and without a valid `index.shs` file
- templates - section templates go here
- secret - users, passwords and other Seecret data should be stored here
- storage - random data storage for your webapp

## Variables that we think are cool!

![](https://f.sakamoto.pl/d6584c01-1c48-42b9-935b-d9a89af4e071file_101.jpg)

- get_data - holds data from GET parameters
	- /?test=asdf -> `${get_data[test]}` == `"asdf"`
- params - holds parsed data from URL router
	- /profile/test (assuming profile/:name) -> `${params[name]}` == `"test"` 
- post_data - same as above, but for urlencoded POST params
	- test=asdf -> `${post_data[test]}` == `"asdf"`
- post_multipart - contains paths to uploaded files from multipart/form-data POST requests. **WARNING**: it doesn't hold field names yet, it relies on upload order for identification
	- first file (in upload order) -> `cat ${post_multipart[0]}`
	- second file -> `cat ${post_multipart[1]}`
- r - misc request data
	- authorization
	- content_boundary
	- content_boundary
	- content_length
	- content_type
	- headers
	- host
	- host_portless
	- ip
	- post
	- proto
	- status
	- uri
	- url
	- user_agent
	- view
	- websocket_key
- cfg - server and app config - see `config/master.sh` for more details
	
## Fun stuff

- To prevent running malicious scripts, by default only scripts with extension `.shs` can be run by the server, but this can be changed in the config.
- ${cfg[index]} ignores the above - see config/master.sh
- Trans rights!
- SHS stands for Shell Server.
