# HTTP.sh

the *coolest* web framework (in Bash) to date.

We now have an IRC channel! Join #http.sh @ irc.libera.chat

## Documentation

We have some guides and general documentation in the [docs](docs/) directory. Among them:

- A [quick start](docs/quick-start.md) guide
- General [directory structure](docs/directory-structure.md)
- [CLI usage](docs/running.md)
- [Tests](docs/tests.md)
- [HTTP Router](docs/router.md)
- [Template engine](docs/template.md)
- [Script integrations](docs/util.md)
- [List of security fixes](docs/sec-fixes/)

## Dependencies

Absolutely necessary:

- Bash (5.x, not interested in backwards compat)
- either [Ncat](https://nmap.org/ncat) (not openbsd-nc, not netcat, not nc) or socat, or a combo of both
- GNU grep/sed

Full list of dependencies: [required](src/dependencies.required), [optional](src/dependencies.optional).

## Known faults

- if ncat fails to bind to `[::]`, change the bind to `127.0.0.1` or `0` in `config/master.sh`
- `$post_multipart` doesn't keep original names - could be fixed by parsing individual headers from the multipart request instead of skipping them all
- websocket impl isn't properly finished
- fails with an empty response, instead of throwing 400/500

## Variables that we think are cool!

![](https://f.sakamoto.pl/d6584c01-1c48-42b9-935b-d9a89af4e071file_101.jpg)

(this data may be slightly outdated. Full docs TODO.)

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
