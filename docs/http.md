# HTTP - the proto, the API

very work in progress file.

---

## GET/POST parameters

- `${get_data["param"]}`
- `${post_data["param"]}`

Case-insensitive. If K/V pairs aren't used (but a string is provided, just without `=`) then
it can be accessed through `${get_data}` / `${post_data}` (array element 0).

### Arrays

HTTP does arrays through concatenating multiple parameters with the same name. In our case, values
are passed to a secondary array, and a reference to it is left for application use.

```
GET asdf/?a=1&a=2&a=3&b=1
```

will result in:

```
declare -A get_data=([b]="1" [a]="[array]" )
```

To get the value set out of an array, call `http_array <param_name> <output_name>`. For instance:

```
#!/bin/bash
if ! http_array a array; then
	echo "Not an array"
	return
fi

for (( i=0; i<${#array[@]}; i++ )) {
	echo "a[$i]=${array[i]}"
}
```

