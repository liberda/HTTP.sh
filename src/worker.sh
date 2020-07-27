#!/bin/bash

# worker.sh - setup and control of workers

# worker_add(name, interval)
function worker_add() {
	if [[ -x "workers/$1/worker.sh" ]]; then
		while true; do workers/$1/worker.sh; sleep $2; if [[ $(cat workers/$1/control) == "die" ]]; then echo "" > workers/$1/control; while true; do if [[ $(cat workers/$1/control) == "run" ]]; then echo "" > workers/$1/control; break; fi; sleep $2; done; fi; done &
	else
		echo "You have a broken worker configuration! Please check if worker.sh in worker $1 is executable."
	fi
}

# worker_kill(name)
function worker_kill() {
	echo "die" > workers/$1/control
}

# worker_resume(name)
function worker_resume() {
	echo "run" > workers/$i/control
}