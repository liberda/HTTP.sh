#!/bin/bash
enable -f $(dirname $0)/target/debug/libhttpsh.so array
declare -A str
str[title]='nyaa!'
array $1

