# HTTP.sh: template engine

We have a basic template engine! It's somewhat limited in capabilities compared to engines you might
have previously used, but we're working on making it better :3

Note: the `templates` subdirectory in the HTTPsh repo is entirely unrelated to the template engine,
and it will be removed in a future release. Please ignore it.

For practical examples, see the [template examples](template-examples.md) page.

## Tag schema

- Tags always start with `{{` and end with `}}`.
- Tags can't include whitespace, outside of special iter/boolean tags defined below
- Tag identifiers can contain letters, numbers, dashes and underscores (`[a-zA-Z0-9_-]`).
  Other characters may work but are NOT RECOMMENDED.
- Tag identifiers are always prefixed by the tag type. This is also reflected in the code, outside
  of simple replaces which MUST skip the dot in the array assignment.
- Identifiers are represented by `<name>` later in this document.

## API

`render <assoc_array> <file> [recurse]`

The first param points to an associative array containing the replacement data. Second one points
to a file containing the template itself. Third is optional, and controls whether `render` will
recurse or not. This is mostly used internally, you likely won't ever need to set it.

## Simple replace

| | |
| --- | --- |
| In the template | `{{.<name>}}` |
| In the code | `array[<name>]="<value>"` |
| Notes | For your convenience, code representation skips the dot. |

**Important**: to simplify your life (and protect your application), simple replaces ALWAYS use
html_encode behind the scenes. This means that you're safe to assign any value to them without
prior sanitization.

## Raw replace

| | |
| --- | --- |
| In the template | `{{@<name>}}` |
| In the code | `array[@<name>]="<value>"` |

Same as a simple replace, but doesn't do html_encode. Useful if you want to guarantee unmangled
output (for filling out hidden form values, etc.)

## Template includes

| | |
| --- | --- |
| In the template | `{{#<path>}}` |
| In the code | n/a |

Template includes are special, in that you don't have to define them in the array.
They get processed first to "glue together" one singular template.

Currently, the path starts at the root of HTTPsh's directory. We don't support expanding variables
inside the include tag, so for now you'll need to hardcode `{{#app/templates/...}}`. This will
likely get changed in a future release, starting the path in your namespace.

**Warning**: No recursion is supported within included templates; This means that you can't have
an "include chain". Furthermore, some interactions between included templates and loops/ifs are
a bit wonky; This will get ironed out at some point (sorry!)

## Boolean if statements

| | |
| --- | --- |
| In the template | `{{start ?<name>}} ... {{end ?<name>}}` |
| In the template (alt.) | `{{start ?<name>}} ... {{else ?<name>}} ... {{end ?<name>}}` |
| In the code | `array[?<name>]=_` |
| Notes | Can be used both inline and not. See [examples page](template-examples.md) for more details. |

**Important**: Currently, you can't have two checks for the same variable. If needed, set a second
variable in the code and check for that. Fix TBD.

This is a *boolean operator*. The only supported mode of operation is checking whether
a variable is set or not.

## Loops

| | |
| --- | --- |
| In the template | `{{start _<name>}} ... {{end _<name>}}` |
| In the code | `array[_name]="<reference>"` |

Each loop extracts the area between start/end markers, and executes another `render` internally.
You have to provide it with an "array of arrays", essentially an intermediate holding references.
This is usually done through `nested_declare <array>` and `nested_add <array> <temporary>`.

Essentially, this boils down to:

```
nested_declare list # "array of arrays"
declare -A elem # temporary element
for i in {1..32}; do
	elem[item]="$i" # assign $i to the temporary element
	nested_add list elem # add elem to list; this creates a copy you can't modify
done
# once we have a full list of elements, assign it to the array passed to render
str[_list]=list
```

A more detailed usage description is available on the [template examples](template-examples.md) page.

### Leaky temporary array

You should excercise caution when handling the temporary arrays; Calling `unset elem` on the end
of each loop may be a good idea if you can't guarantee that all of your elements will always have
values. Otherwise, values from previous iterations may leak to the current one, potentially causing confusion.

## Loop indexes

| | |
| --- | --- |
| In the template | `{{-index}}` |
| In the code | n/a |
| Notes | Doesn't resolve at all outside loops. Counter starts at 0 and gets incremented with every element. |

## Date pretty-printing

| | |
| --- | --- |
| In the template | `{{+<name>}}` |
| In the code | `array[+<name>]="<timestamp>"` |

This saves you from a few messy calls to `date`. Input is a UNIX timestamp.

The date format can be overriden by changing a config variable. Default is
`cfg[template_date_format]='%Y-%m-%d %H:%M:%S'`.

## URI slices

| | |
| --- | --- |
| In the template | `{{-uri-<level>}}` |
| In the code | n/a |
| Notes | Level must be a number. URI is always terminated with a slash, even if your last object is a file. |

Takes the current URI path, and slices it using `/` as a delimeter, going from the left.

Given an URL `http://localhost:1337/hello/world/asdf`...

- `{{-uri-0}}` -> `/`
- `{{-uri-1}}` -> `/hello/`
- `{{-uri-2}}` -> `/hello/world/`
- `{{-uri-3}}` -> `/hello/world/asdf/`
- `{{-uri-4}}` -> none (higher values are always empty)

This is very useful when creating menus; Instead of relying on hardcoded values, if the page is always
on *the same URI level*, one can create links such as `<a href="{{-uri-2}}meow">(...)</a>`, which will always
resolve to the same file; This eliminates a whole class of bugs where trailing slashes would break some
poorly-written relative URLs.
