#!/usr/bin/env bash
echo '<!DOCTYPE html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">'

if [[ "${meta[title]}" != "" ]]; then echo "<title>$(html_encode "${meta[title]}") - ${cfg[title]}</title>"; else echo "<title>${cfg[title]}</title>"; fi
if [[ "${meta[author]}" != "" ]]; then echo "<meta name='author' content='$(html_encode "${meta[author]}")'>"; fi
if [[ "${meta[description]}" != "" ]]; then echo "<meta name='description' content='$(html_encode "${meta[description]}")'>"; fi
if [[ "${meta[keywords]}" != "" ]]; then echo "<meta name='keywords' content='$(html_encode "${meta[keywords]}")'>"; fi
if [[ "${meta[refresh]}" != "" ]]; then echo "<meta http-equiv='refresh' content='$(html_encode "${meta[refresh]}")'>"; fi
if [[ "${meta[redirect]}" != "" ]]; then echo "<meta http-equiv='refresh' content='0; URL=$(html_encode "${meta[redirect]}")'>"; fi
if [[ "${meta[css]}" != "" ]]; then echo "<link rel='stylesheet' type='text/css' href='$(html_encode "${meta[css]}")'/>"; fi
if [[ "${meta[title]}" != "" ]]; then echo "<meta property='og:title' content='$(html_encode "${meta[title]}")'>"; fi
#if [[ "${meta[og:type]}" != "" ]]; then echo "<meta property='og:type' content='${meta[og:type]}'>"; fi
if [[ "${cfg[url]}" != "" ]]; then echo "<meta property='og:url' content='$(html_encode "${cfg[url]}")'>"; fi
#if [[ "${meta[og:image}" != "" ]]; then echo "<meta property='og:image' content='${meta[og:image]}'>"; fi
if [[ "${meta[lang]}" != "" ]]; then echo "<meta property='og:locale' content='$(html_encode "${meta[lang]}")'>"; fi
if [[ "${meta[description]}" != "" ]]; then echo "<meta property='og:description' content='$(html_encode "${meta[description]}")'>"; fi
if [[ "${meta[unsafe]}" != "" ]]; then echo "${meta[unsafe]}"; fi

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
