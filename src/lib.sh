#!/usr/bin/env bash

log_dbg() {
	[[ "${cfg[dbg]}" ]] && echo $@
}

