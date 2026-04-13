source config/master.sh
source src/lib.sh
source src/migrate.sh
source src/notORM.sh

# try running the migration system and checking if the migration root gets written
migrate_test_sanity() {
	tst() {
		migrate_check
		if data_get storage/migrations.dat { }; then
			[[ "${res[0]}" == "initial" ]] && return 0
		fi
		return 1
	}
}

migrate_test_basic() {
	store="storage/migrate_test.dat"
	migration="app/migrations/${EPOCHSECONDS}_test$RANDOM.sh"
	
	prepare() {
		a=("meow" "nyaa")
		data_add "$store" a
		a=("nyaa" "...")
		data_add "$store" a
	}

	tst() {
		set -x
		[[ "$(cat "$store.cols")" != 2 ]] && return 1
		cat <<"EOF" > "$migration"
cb() {
	data[2]='1337'
	data_add $store.new data
}
data_iter $store { } cb
mv $store.new $store
mv $store.new.cols $store.cols
EOF
		migrate_check
		[[ "$(cat "$store.cols")" != 3 ]] && return 1
		if ! data_get $store { 1337 2 }; then
			return 1
		fi
	}

	cleanup() {
		rm "$store" "$migration"
	}
}


subtest_list=(
	migrate_test_sanity
	migrate_test_basic
)
