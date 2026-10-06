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

	while read -r fn; do
		migration_name="$(basename "$fn")"
		if ! data_get storage/migrations.dat { "$migration_name" }; then
			ts="${migration_name%%_*}"

			if [[ ! "$ts" =~ ^[0-9]+$ ]]; then
				echo "[migrations] $fn has an invalid name. See docs/migrations.md for more information."
				exit 1
			fi

			if [[ "$ts" -lt "$initial" ]]; then
				log_dbg "[migrations] skipping $migration_name"
				continue
			fi

            if [[ $init ]]; then
                echo "[migrations] WARNING: running $migration_name after application initalization (clock out of date or misplaced migration?)"
            else
			    echo "[migrations] running $migration_name"
            fi

			source "$fn"
			if [[ $? != 0 ]]; then
                echo "[migrations] failed to run $migration_name"
                exit 1
            fi

			a=("$fn" "$EPOCHSECONDS")
			data_add storage/migrations.dat a || return $?
		else
			log_dbg "[migrations] $migration_name ran at ${res[1]}"
		fi
	done < <(find "${cfg[namespace]}/migrations/" "src/migrations/" -type f)
}
