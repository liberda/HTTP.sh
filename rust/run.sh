#!/bin/bash
enable -f $(dirname $0)/target/debug/libhttpsh.so -n array_
declare -A str
str[title]='nyaa!'
array_ $1

