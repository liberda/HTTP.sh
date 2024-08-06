# the test framework

We have a small test harness! It lives in `./tst.sh` in the root of the HTTP.sh repo. It's inspired
by some init systems, and a bit influenced by how APKBUILD/PKGBUILDs are structured. A very basic
test is attached below:

```
tst() {
	return 0
}
```

A `tst()` function is all you need in a test. Running the test can be done like so:

```
$ ./tst.sh tests/example.sh
OK: tests/example.sh


Testing done!
OK:   1
FAIL: 0
```

If running multiple tests is desired, I recommend calling `./tst.sh tests/*`, and prepending the
filenames with numbers to make sure they run in the correct sequence.

You can also contain multiple tests in a file by grouping them into a function, and then adding the
function names to an array:

```
a() {
	tst() {
		return 0
	}
}
b() {
	tst() {
		return 1
	}
}

subtest_list=(
	a
	b
)
```

This will yield the following result *(output subject to change)*:

```
--- tests/example.sh ---
OK: a
FAIL: b
(res: )


Testing done!
OK:   1
FAIL: 1
```

Of note: `tst.sh` is designed in a way where *most* functions will fall through; If you'd like to
run the same test against a different set of checks (see below) then you *don't* need to redefine
the `tst()` function, just changing the checks is enough.

---

## return codes

The following return codes are defined:

- 0 as success
- 1 as error (test execution continues)
- 255 as fatal error (cleans up and exits immediately)

## determining success / failure 

Besides very simple return-code based matching, `tst.sh` also supports stdout matching with the
following variables:

- `match` (matches the whole string)
- `match_sub` (matches a substring)
- `match_begin` (matches the beginning)
- `match_end` (matches the end)
- `match_not` (inverse substring match)

If any of those are defined, all except fatal return codes are ignored. If more than one of those
is defined, it checks the list above top-to-bottom and picks the first one that is set, ignoring
all others. 

## special functions

The framework defines two special functions, plus a few callbacks that can be overriden:

### prepare

`prepare` runs **once** after definition, right before the test itself. As of now, it's the only
function that gets cleaned up after each run (by design; see section `statefullness` below)

By default (undefined state), `prepare` does nothing.

```
prepare() {
	echo 'echo meow' > app/webroot/test.shs
}

tst() {
	curl localhost:1337/test.shs
}

match="meow"
```

*(note: this test requires tst.sh to be used with http.sh, and for http.sh to be running)*

### cleanup

`cleanup` runs after every test. The name should be self-explanatory. Define as `cleanup() { :; }`
to disable behavior from previous tests.

By default (undefined state), `cleanup` does nothing.

```
prepare() {
	echo 'echo meow' > app/webroot/test.shs
}

tst() {
	curl localhost:1337/test.shs
}

cleanup() {
	rm app/webroot/test.shs
}

match="meow"
```

*(note: same thing as above)*

### on_success, on_error, on_fatal

Called on every success, failure and fatal error. First two call `on_{success,error}_default`,
which increments the counter and outputs the OK/FAIL message. The third one just logs the FATAL,
cleans up and exits. Overloading `on_fatal` is not recommended; While overloading the other two,
make sure to add a call to the `_default` function, or handle the numbers gracefully by yourself.

## statefullness

This framework is designed in a way where a lot of the state is inherited from previous tests. This
is by-design, to make sure that there's less repetition in the tests themselves. It is up to the
author of the tests to remember about cleaning up variables and other state that could affect any
further tests in the chain.

Currently, state is cleaned up under the following circumstances:
- all `match` variables get cleaned up after every test
- `prepare()` function is reset after every test (so, each definition of `prepare` will run
  exactly *once*)
- upon switching files, `tst()` and `cleanup()` get reset to initial values. Of note, those two
  **do** get inherited between subtests in a single file!
- upon termination of the test harness, it tries to kill all child processes

The following state **is not** cleaned up:
- `tst()` and `cleanup()` between subtests in a single file
- `on_error()`, `on_success()` functions
- any global user-defined variables, also between files
- any started processes
- any modified files (we don't have a way to track those atm, although I may look into this)
