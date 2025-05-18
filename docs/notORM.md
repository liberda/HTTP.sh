# HTTP.sh's notORM, the not quite arbitrary data store

notORM aims to be a generic interface between bash and databases, for storing ASCII and
UTF-8 strigns. Currently it only supports file-backed CSV-like stores, but our aim is to
make it talk with several SQL databases, exposing a common API to the application.

For some examples, check out [unit tests](../tests/04-notORM.sh).

## What notORM can't do

- store 0x00, 0x01 and 0x02; Other non-printable characters are unsupported, but may work.
- do complex matches. those can be reimplemented manually with `data_iter`
- guarantee full security. data does get sanitized, but remember to treat unsafe input
  very carefully.
- cook you dinner (haven't tried tho)

## Public functions

The API is still evolving. Functions marked in italics are to be deprecated:

- data_add (adds an entry. creates a store if it does not exist)
- data_get (retrieves the first entry that matches constraints)
- data_iter (calls an user-defined function on every match)
- *data_replace_value* (replaces one cell on all rows that match)
- data_replace (replaces a row with a bash array on all rows that match)
- data_yeet (removes all rows that match)

For in-depth descriptions, see references in `src/notORM.sh`. Each function has some usage
notes in a comment above it.

## Calling conventions

Currently, notORM supports two calling conventions for calls that select data:
- original (positional arguments, different for every function)
- improved (special selectors, generic for all getters).

It is recommended to only use the improved calling convention:

```
COMMAND STORE_PATH { SEARCH } [additional_args]
COMMAND STORE_PATH { SEARCH COLUMN } [additional_args]
COMMAND STORE_PATH { SEARCH COLUMN } { SEARCH COLUMN } (...) [additional_args]
```

- `COMMAND` can be one of `data_get`, `data_iter`, `data_yeet`. (`data_replace` in
  a future version, TBD)
- `STORE_PATH` selects a specific notORM store file
- `{` is a literal curly brace. it has to be paired with `}` after a search term.
- `SEARCH` is a literal that has to match when selecting a row. Optional, left out matches
  all possible rows.
- `COLUMN` specifies which column the `SEARCH` term should be matched on. 0-indexed,
  optional, defaults to 0 (usually unique key or autoincrement ID)
- `}` is a literal closing curly brace. it may be followed by another `{`, or
  command-specific arguments.

### Example usage

```
data_get storage/asdf.dat { "meow" }   # matches "meow" on 0th column
data_get storage/asdf.dat { "meow" 1 } # matches "meow" on 1st column
data_get storage/asdf.dat { "meow" 1 } { 1337 } # matches "meow" on 1st, and "1337" on 0th
data_get storage/asdf.dat { } # matches first record in the store
```

## Autoincrement key

By default, all keys are modified manually. That is, what you put in is what you take out.
`data_add` has a special mode which inserts a number as the 0th element in each entry:

```
data_add STORE_PATH ARRAY AUTOINCREMENT
```

It's important to warn that in the current impl this is much more resource-intensive than
a plain `data_add`, as it needs to find the last element in the store and increment the
counter. A rewrite is pending.

### Example usage

```
a=(123 456)
data_add store a true
data_get store { }
declare -p res # res=(0 123 456)
```

## Iterators

```
data_iter STORE_PATH { ... } CALLBACK
```

`CALLBACK` is the name of an user-defined function that will get called on every matched
entry. Common debug value is `x`, which will run `declare -p data`, listing all records.

Returning value `255` from the callback will terminate the iterator.

### Example usage

```
cb() {
	echo "${data[0]}"
}
data_iter store { } cb
```

Depending on your coding style, calling `unset` on the function after use may be desired.

