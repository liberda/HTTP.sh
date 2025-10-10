# utils: integrating scripts with http.sh

HTTP.sh provides a number of useful APIs designed to make interfacing with HTTP and browsers easier.
Some of those (especially notORM) are also useful in a CLI environment, to help with migrations and
other administrative tasks.

## Invocation

Utils integrate into HTTP.sh through calling the main script, with the utility name as the first
parameter. So, for `meow.sh` the invocation would be `./http.sh meow`, or `./http.sh meow [params]`
if the util takes any parameters.

Utils are automagically started within the environment, and otherwise work like normal scripts.
Of note:

- `$0` is always the `./http.sh` invocation, not your script name
- script name is instead stored in `$HTTPSH_SCRIPTNAME`
- `$@` contain parameters to the utility, not a full invocation.
- at the present, only the `master.sh` config is loaded
- the environment is equivalent to `./http.sh shell`

A list of utilities can be obtained by calling `./http.sh utils`.

## Creating your own

Simply create a shell script in your namespace's util directory (that's usually `app/util/`), and
mark it as executable. It has to have `.sh` as an extension, but shebang currently doesn't matter.

It's recommended that if your util takes any positional parameters, it should check for $1 being
set, and display a help message. An example of such script is listed below.

```
if [[ ! "$1" || "$1" == "help" ]]; then
	echo "usage: $0 $HTTPSH_SCRIPTNAME <action>

Action can be one of:
  meow - Mrrrrrrrp!
  help - This message."
	exit 1
fi

# script continues here...
```

## Built-in utils

The following scripts are generic helpers shipped with HTTP.sh. We hope they'll come in handy.

### notORM

WIP. Currently can only dump a store out to the terminal:

```bash
$ ./http.sh notORM dump storage/new.dat
declare -a data=([0]="0" [1]="domi" [2]="http://sdomi.pl/" [3]="" [4]="XOaj44smtzCg1p88fgG7bEnMeTNt361wK8Up4BKEiU747lcNIuMAez60zEiAaALWMwzcQ6" [5]="0" [6]="meow~" [7]="RCszUuBXQI")
 (…)
```

### bump

Acknowledges a version after a HTTP.sh update. Takes no parameters.

## Future plans

- List a description for each util on the `./http.sh utils` page. This would require storing more
  metadata on the utils, TBD.
- more 1st-party utils!
- more work on notORM util, ideally it should allow one to do all actions on the DB
