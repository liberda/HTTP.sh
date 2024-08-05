# HTTP.sh: quick start

Welcome to the exciting world of Bash witchery! I'll be your guide on this webdev adventure today.

## about HTTP.sh

HTTP.sh is a very extensive web framework. I use it for quick and dirty hacks, and I "designed" it
in a way where you don't need to write a lot of code to do some basic stuff. I'm also gradually
adding middleware that helps you do more advanced stuff. With some regards, there are already
multiple ways one could implement a web app in HTTP.sh; Thus, I feel like I need this to be heard:

**There are no bad ways to write code here.** You can still write *bad code*, but this is a safe
space where nobody shall tell you "Y is garbage, you should use X instead!";

This strongly applies to specific features of the framework: You can use the templating engine, or
you can just `echo` a bunch of stuff directly from your script. You can use the URL router, or you
could just name your scripts under the webroot in a fancy way. **As long as it works, it's good :3**

## Getting started

First, clone the repository. I'm sure you know how to do that; Afterwards, try running:

```
./http.sh init
./http.sh
```

`init` will lay out some directories, and running it w/o any params will just start the server.
If you're missing any dependencies, you should now see a list of them.

By default, http.sh starts on port 1337; Try going to http://localhost:1337/ - if you see a welcome
page, it's working!!

We have a "debug mode" under `./http.sh debug`. Check [running.md](running.md) for more options.

## Basic scripting

By default, your application lives in `app/`. See [directory-structure.md](directory-structure.md)
for more info on what goes where. For now, go into `app/webroot/` and remove `index.shs`. That
should bring you to an empty directory listing; Static files can be put as-is into `app/webroot/`
and they'll be visible within the directory!

To create a script, make a new file with `.shs` extension, and start writing a script like normal.
All of your `stdout` (aka: everything you `echo`) goes directly to the output. Everything sent to
`stderr` will be shown in the `./http.sh debug` output. 

## Parameters

There are a few ways of receiving input; The most basic ones are `get_data` and `post_data`, which
are associative arrays that handle GET params and POST (body) params, respectively. Consider the
following example:

```
#!/bin/bash
echo '<html><head><meta charset="utf-8"></head><body>'

if [[ ! "${get_data[example]}" ]]; then
	echo '<form>
			<input type="text" name="example">
			<input type="submit">
		</form>'
else
	echo "<p>you sent: $(html_encode "${get_data[example]}")</p>"
fi

echo '</body></html>'
```

When opened in a browser, this example looks like so:

![screenshot of a simple web page. there's a text box, and a button saying Submit Query](https://f.sakamoto.pl/IwIalnWw.png)

... and after submitting data, it looks like that:

![screenshot of another page. it says "you sent: meow!"](https://f.sakamoto.pl/IwIy0thg.png)

## Security

Remember to use sufficient quotes in your scripts, and escape untrusted data (read: ALL data you
didn't write/create yourself. This is especially important when parameter splitting may occur;
For instance, consider:

```
rm storage/${get_data[file]}
```

vs

```
rm -- "storage/$(basename "${get_data[file]}")"
```

The first one can fail due to:
- spaces (if `?file=a+b+c+d`, then it will remove `storage/a`, `b`, `c` and `d`). Hence, you get
  arbitrary file deletion.
- unescaped filename (param containing `../` leads to path traversal)
- unterminated parameter expansion (`--` in `rm --` terminates switches; after this point, only
  file names can occur)

Furthermore, if you're displaying user-controlled data in your app, remember to use `html_encode`
to prevent cross-site scripting attacks.
