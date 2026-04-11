#!/usr/bin/env bash
# migrate.sh - support for custom notORM migrations

migrate_check() {
	local init initial a fn ts

	# check for migrations to be run
	[[ ! -d "${cfg[namespace]}/migrations" ]] && return 0

	# write initial startup time to match all migrations coming after
	if ! data_get storage/migrations.dat { "initial" }; then
		log_dbg "[migrations] writing initial migration"

        init=true
        initial="$EPOCHSECONDS"

		a=("initial" "$initial")
		data_add storage/migrations.dat a

        # Explicitly not returning here because missplaced migrations would be
        # ran silently anyway on next startup
    else
        initial="${res[1]}"
    fi

	while read fn; do
		if ! data_get storage/migrations.dat { "$fn" }; then
			ts="${fn%%_*}"

			if [[ ! "$ts" =~ ^[0-9]+$ ]]; then
				echo "[migrations] $fn has an invalid name. See docs/migrations.md for more information."
				exit 1
			fi

			if [[ "$ts" -lt "$initial" ]]; then
				log_dbg "[migrations] skipping $fn"
				continue
			fi

            if [[ $init ]]; then
                echo "[migrations] WARNING: running $fn after application initalization (clock out of date or missplaced migration?)"
            else
			    echo "[migrations] running $fn"
            fi

			source "${cfg[namespace]}/migrations/$fn"
			if [[ $? != 0 ]]; then
                echo "[migrations] failed to run $migration_name"
                exit 1
            fi

			a=("$fn" "$EPOCHSECONDS")
			data_add storage/migrations.dat a || return $?
		else
			log_dbg "[migrations] $fn ran at ${res[1]}"
		fi
	done < <(ls "${cfg[namespace]}/migrations/")
}
