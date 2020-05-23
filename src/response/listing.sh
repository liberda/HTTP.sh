printf "HTTP/1.0 200 OK
${cfg[extra_headers]}\r\n\r\n"

source templates/head.sh

printf "<h1>Index of $([[ ${r[url]} == '' ]] && echo '/' || echo ${r[url]})</h1>"

if [[ ${cookies[username]} != '' ]]; then
	echo "Logged in as ${cookies[username]}"
fi

printf "<table>
<tr>
	<th>File</th>
	<th>Size</th>
	<th>Date</th>
</tr>
<tr>
	<td><a href='../'>..</a></td><td></td><td></td>
</tr>"
IFS=$'\n' 

for i in $(ls ${r[uri]}); do
	unset IFS
	stats=($(ls -hld "${r[uri]}/$i")) # -hld stands for Half-Life Dedicated
	if [[ -d ${r[uri]}'/'$i ]]; then
		printf "<tr><td><a href='$(echo -ne ${r[url]})/$i/'>$i</a></td><td>&lt;DIR&gt;</td><td>${stats[5]} ${stats[6]} ${stats[7]}</td></tr>"
	else
		printf "<tr><td><a href='$(echo -ne ${r[url]})/$i'>$i</a></td><td>${stats[4]}B</td><td>${stats[5]} ${stats[6]} ${stats[7]}</td></tr>"
	fi
done
			
printf "</table><p><i>HTTP.sh server on ${r[host]}</i></p><p>laura is cute</p>"
