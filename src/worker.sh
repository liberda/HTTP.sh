#!/usr/bin/env bash
# worker.sh - setup and control of workers

# worker_add(name, interval)
function worker_add() {
	if [[ -x "${cfg[namespace]}/workers/$1/worker.sh" ]]; then
		echo "[WRKR] adding worker $1"
		{
			shopt -s extglob
			x() { declare -p data;} # for notORM
			source config/master.sh
			source src/account.sh
			source src/mail.sh
			source src/mime.sh
			source src/misc.sh
			source src/notORM.sh
			source src/template.sh
			while true; do
				source "${cfg[namespace]}/workers/$1/worker.sh"
				sleep $2
				if [[ $(cat "${cfg[namespace]}/workers/$1/control") == "die" ]]; then
					echo "" > ${cfg[namespace]}/workers/$1/control
					while true; do
						if [[ $(cat "${cfg[namespace]}/workers/$1/control") == "run" ]]; then
							echo "" > "${cfg[namespace]}/workers/$1/control"
							break
						fi
						sleep $2
					done
				 fi
			done
		} &
	else
		echo "[WRKR] Broken config - workers/$1/worker.sh does not exist, or is not executable?"
	fi
}

# worker_kill(name)
function worker_kill() {
	echo "die" > "${cfg[namespace]}/workers/$1/control"
}

# worker_resume(name)
function worker_resume() {
	echo "run" > "${cfg[namespace]}/workers/$1/control"
}
