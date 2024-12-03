# HTTP.sh: URL router

After running `./http.sh init`, your `app` directory should include a file called `routes.sh` - this
is where you define custom routes. The syntax is as follows:

```
router "/uri/path" "${cfg[namespace]}/views/file.shs"
```

This can be used to remap files that are already in `webroot`, but to prevent confusion, it is
recommended to make a separate directory for routed files. In other HTTP.sh projects, it's usually
`views`.

The router also can be used to pass parameters:

```
router "/user/:username" "${cfg[namespace]}/views/profile.shs"
router "/user/:username/:postid" "${cfg[namespace]}/views/post.shs"
```

All router parameters are available at runtime through `${params[]}` associative array.
A sample `profile.shs` could look like this:

```
#!/bin/bash

echo "$(html_encode "${params[username]}")'s profile"
```

## Limitations

- The param name can only contain the following characters: `[A-Za-z0-9]`
- Currently, the param itself can only contain the following characters: `[A-Za-z0-9.,%:\\-_]`;
  Otherwise, the route won't match, and you'll likely get a 404. Support for other special chars
  will be added somewhere down the line.
- Router takes precedence over normal file matching; This could allow one to override a file.
