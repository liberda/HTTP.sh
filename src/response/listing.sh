echo -ne "HTTP/1.0 200 OK
content-type: text/html
${cfg[extra_headers]}\r\n\r\n"

source templates/head.sh

echo "<h1>Index of $([[ ${r[url]} == '' ]] && echo '/' || echo $(html_encode ${r[url]}))</h1>"

if [[ ${cookies[username]} != '' ]]; then
	echo "Logged in as $(html_encode ${cookies[username]})"
fi

echo "<table>
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
	if [[ -d "${r[uri]}"'/'"$i" ]]; then
		echo "<tr><td><a href='$(html_encode "${r[url]}/$i/")'>$(html_encode "$i")</a></td><td>&lt;DIR&gt;</td><td>${stats[5]} ${stats[6]} ${stats[7]}</td></tr>"
	else
		echo "<tr><td><a href='$(html_encode "${r[url]}/$i")'>$(html_encode "$i")</a></td><td>${stats[4]}B</td><td>${stats[5]} ${stats[6]} ${stats[7]}</td></tr>"
	fi
done
			
echo "</table><p><i>HTTP.sh server on $(html_encode ${r[host]})</i></p><p>meow!</p>"
