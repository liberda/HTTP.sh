# File / Directory structure

(alphabetical order; state for 2024-08-05)

- `config` contains per-vhost configuration settings. `config/master.sh` gets loaded by default,
  `config/<hostname>[:port]` gets loaded based on the `Host` header.
- `docs` is what you're reading now. Hi!!
- `secret` is where user data gets stored. think: user accounts and sessions.
- `src` contains the majority of HTTP.sh's code.
	- `response/*` are files executed based on computed return code. `response/200.sh` is a bit
	  special, because it handles the general "success" path. Refactor pending.
	- `account.sh` is the middleware for user account management
	- `dependencies.*` store the list of required and optional deps, newline delimetered
	- `mail.sh` has some crude SMTP code, for sending out mails
	- `mime.sh` contains a glue function for handling special cases where `file` command doesn't
	  return the proper mimetype
	- `misc.sh` consists of functions that didn't really fit anywhere else. Of note, `html_encode`,
	  `url_encode`, `url_decode`, `header` and various cookie functions all live there for now.
	- `notORM.sh` is, as I said, not an [ORM](https://en.wikipedia.org/wiki/Object%E2%80%93relational_mapping)
	- `route.sh` defines a small function for handling adding the routes
	- `server.sh` is where most of the demons live
	- `template.sh` is where the rest of the demons live
	- `worker.sh` is the literal embodiment of "we have cron at home"; workers are just background
	  jobs that run every n minutes; you can also start and stop them on will! *fancy*
	- `ws.sh` is an incomplete WebSocket implementation
- `storage` is like `secret`, but you can generally use it for whatever
- `templates` will be moved/removed soon (`head.sh` has *nothing* to do with the current templating
  system; it has some handlers for remaking things you put into `meta[]` array into HTML `<head>`
  fields. Should not be used, at least not in its current form.)
- `tests` is where all the tests live!

The actually important files are:
- `http.sh` - run this and see what happens
- `tst.sh` - [the test suite](tests.md) 

## suggested skeleton structure in `app/`

FYI: this is merely a suggestion. `./http.sh init` will create some of those directories for you,
but it's fine to move things around. A lot of it can be changed within `config/master.sh`, even the
directory name itself!

- `src` for various backend code
- `templates` for HTML in our special templating language
- `views` for individual pages / endpoints
- `webroot` for static files, or .shs scripts that don't use the router
- `config.sh` has some general, always-included stuff
- `routes.sh` configures the router; entries should point into `views/`
- `localcfg.sh` may be sourced from `config.sh` and contain only local config (useful for developing
  stuff with others through git, for instance; `localcfg.sh` should then be added to `.gitignore`)
