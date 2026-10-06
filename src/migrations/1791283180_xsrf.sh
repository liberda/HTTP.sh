#!/bin/bash
[[ ! -f secret/sessions.dat ]] && return
cb() {
	data[4]="$(dd if=/dev/urandom bs=24 count=1 status=none | xxd -p)"
	data_add secret/sessions2.dat data
}
data_iter secret/sessions.dat { } cb
mv secret/sessions2.dat secret/sessions.dat 
mv secret/sessions2.dat.cols secret/sessions.dat.cols
