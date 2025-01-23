#!/bin/bash
enable -f $(dirname $0)/target/debug/libhttpsh.so -n array
declare -A str
str[title]='nyaa!'
array $1

