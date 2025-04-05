# HTTP.sh: template usage examples

## Basic example

Create a new .shs file with the following contents:

```
#!/usr/bin/env bash
declare -A str
str[title]="Hello, world!"
str[test]="meow"

render str "${cfg[namespace]}/templates/main.htm"
```

`render` is the core of the templating engine; it takes an assoc array, iterates over it, applies
additional magic and outputs the response directly to stdout. It is likely the final thing you want
to run in your script.

The script above has referenced an HTML file; For this example, we put it under
`app/templates/main.htm`, but you're free to use any directory structure for this.

```
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>{{.title}}</title>
</head>
<body>
	{{.test}}
</body>
</html>
```

![netscape 3.06 gold screenshot, showing our awesome page](https://f.sakamoto.pl/IwILCemig.png)

## Boolean if statements

Following is an example script which simulates a coin toss:

```
#!/usr/bin/env bash
declare -A str
str[title]="Coin flip!"

if (( RANDOM%2 == 0 )); then
	str[?random]=_
fi

render str "${cfg[namespace]}/templates/main.htm"
```

And the corresponding template:

```
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>{{.title}}</title>
</head>
<body>
	{{start ?random}}
		It's heads!
	{{else ?random}}
		It's tails!
	{{end ?random}}
</body>
</html>
```

![another netscape screenshot. the page is titled Coin flip! and it shows that it rolled heads](https://f.sakamoto.pl/IwIQT0d6w.png)

50% of the time the variable will be set, 50% it won't. Hence, it will display either heads or tails :)

Of note: if you hate repeating yourself, this template can be done inline:

```
It's {{start ?random}}heads{{else ?random}}tails{{end ?random}}!
```

The effect is exactly the same. This is quite useful for adding CSS classes.

## Loop example

This API is pending a rewrite due to how convoluted it is.

```
#!/usr/bin/env bash
declare -A str
str[title]="foreach example"

nested_declare list # "array of arrays"
declare -A elem # temporary element
for i in {1..32}; do
	elem[item]="$i" # assign $i to the temporary element
	nested_add list elem # add elem to list; this creates a copy you can't modify
done
# once we have a full list of elements, assign it to the array passed to render
str[_list]=list

render str "${cfg[namespace]}/templates/main.htm"
```

And the template...

```
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>{{.title}}</title>
</head>
<body>
	{{start _list}}
		{{.item}}<br>
	{{end _list}}
</body>
</html>
```

The result repeats the whole "subtemplate" between list start and end:

![list so long that the numbers go off-screen!](https://f.sakamoto.pl/IwI0slukA.png)

This is very useful for rendering data in tables:

```
	<table>
		<tr>
			<th>number</th>
		</tr>
        {{start _list}}
            <tr>
                <td>{{.item}}</td>
                <td>whatever...</td>
            </tr>
        {{end _list}}
	</table>
```

![our example, now rendered as a table](https://f.sakamoto.pl/IwIf39cYw.png)

### integration with notORM

notORM's `data_iter` function works great with nested_add; Body of a callback function can be
treated as equal to a for loop:

```
declare -A elem
nested_declare list
x() {
	elem[ns]="${data[2]}"
	elem[domain]="${data[1]}"
	nested_add list elem
}
data_iter storage/zones.dat "$username" x

str[title]="SERVFAIL :: zone list"
str[_list]=list
```

## date pretty-printing

```
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>{{.title}}</title>
</head>
<body>
	Current time is {{+time}}
</body>
</html>
```

```
#!/usr/bin/env bash
declare -A str
str[title]="time pretty-print"
str[+time]="$EPOCHSECONDS"

render str "${cfg[namespace]}/templates/main.htm"
```

![netscape displays the current date and time](https://f.sakamoto.pl/IwIvf3Axw.png)

If you get quirky with the `<meta http-equiv="refresh" content="1">`, you can even make it
auto update! (don't)

![oh gosh it refreshes now. whyyyyyyyyyyyyyyyy](https://f.sakamoto.pl/simplescreenrecorder-2025-04-05_22.57.36.png)
