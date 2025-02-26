#!/bin/bash

# _ws_to_varlen(num) -> $num
_ws_to_varlen() {
	if [[ $1 -lt 126 ]]; then
		num=$(u8 "$1")
	elif [[ $1 -ge 126 ]]; then # 2 bytes extended
		num=7e$(u16 "$1")
	elif [[ $1 -gt 65535 ]]; then # 8 bytes extended
		num=7f$(u64 "$1")
	fi
}

# _ws_from_varlen(len) -> $len
_ws_from_varlen() {
	if [[ $1 -lt 126 ]]; then
		len="$1"
		return
	elif [[ $1 == 126 ]]; then
		bread 2
	elif [[ $1 == 127 ]]; then
		bread 8
	else # what
		return 1
	fi
	len="$((0x$bres))"
}

# ws_send(payload)
ws_send() {
	local num out len
	len="${#1}"
	[[ $len == 0 ]] && return
	_ws_to_varlen $len

	( echo -n "81$num" | xxd -p -r; echo -n "$1" )
}

ws_recv() {
	local flags fin opcode mask mask_ len bres
	if [[ "$1" ]]; then
		local -n ws_res=$1
	fi
	bread 2 || return 1
	flags=$bres

	fin=$(bit_slice $flags 15..16)
	opcode=$(bit_slice $flags 8..12)
	mask_=$(bit_slice $flags 7)
	len=$(bit_slice $flags 0..7)
	_ws_from_varlen "$len" # check for extended length

	if [[ $mask_ == 1 ]]; then
		bread 4
		# split into 4 separate bytes, separate them with dummy items at odd positions
		# this is saving us a div/mul in the for loop below! :3
		mask=( ${bres:0:2} . ${bres:2:2} . ${bres:4:2} . ${bres:6:2} )
	fi

	bread $len
	if [[ $mask_ == 1 ]]; then
		val=()
		for (( i=0; i<(len*2); i=i+2 )); do
			val+=($(( 0x${bres:i:2} ^ 0x${mask[i%8]} )))
		done
		ws_res="$(printf '%x' ${val[@]} | unhex)" # TODO: variant that doesn't unhex
	else
		ws_res="$(unhex <<< "$bres")"
	fi
}
