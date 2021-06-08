#!/bin/bash
echo '<!DOCTYPE html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">'

if [[ ${meta[title]} ]]; then echo "<title>${meta[title]} - ${cfg[title]}</title>"; else echo "<title>${cfg[title]}</title>"; fi
if [[ ${meta[author]} ]]; then echo "<meta name='author' content='${meta[author]}'>"; fi
if [[ ${meta[description]} ]]; then echo "<meta name='description' content='${meta[description]}'>"; fi
if [[ ${meta[keywords]} ]]; then echo "<meta name='keywords' content='${meta[keywords]}'>"; fi
if [[ ${meta[refresh]} ]]; then echo "<meta http-equiv='refresh' content='${meta[refresh]}'>"; fi
if [[ ${meta[redirect]} ]]; then echo "<meta http-equiv='refresh' content='0; URL=${meta[redirect]}'>"; fi
if [[ ${meta[css]} ]]; then echo "<link rel='stylesheet' type='text/css' href='${meta[css]}'/>"; fi
if [[ ${meta[title]} ]]; then echo "<meta property='og:title' content='${meta[title]}'>"; fi
#if [[ ${meta[og:type]} ]]; then echo "<meta property='og:type' content='${meta[og:type]}'>"; fi
if [[ ${cfg[url]} ]]; then echo "<meta property='og:url' content='${cfg[url]}'>"; fi
#if [[ ${meta[og:image} ]]; then echo "<meta property='og:image' content='${meta[og:image]}'>"; fi
if [[ ${meta[lang]} ]]; then echo "<meta property='og:locale' content='${meta[lang]}'>"; fi
if [[ ${meta[description]} ]]; then echo "<meta property='og:description' content='${meta[description]}'>"; fi
if [[ ${meta[unsafe]} ]]; then echo "${meta[unsafe]}"; fi

echo "<style>
		body {
			background-color: #1a1a1a;
			color: #ccc;
		}
		a {
			color: #3d3;
		}
		a:visited {
			color: #3b3;
		}
		tr:nth-child(2n) {
			background-color: #333;
		}
	</style>
</head>"
