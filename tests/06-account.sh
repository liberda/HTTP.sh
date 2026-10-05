#!/usr/bin/env bash

source src/notORM.sh
source src/account.sh

session_csrf() {
    prepare() {
        _new_session testuser false
        [[ $? != 0 ]] && return 1

        session_id="${session[2]}"
        csrf_token="${session[4]}"
    }

    tst() {
        # existing session and token
        session_get_csrf_token "$session_id"
        [[ $? != 0 ]] && return 1
        [[ "$res" != "$csrf_token" ]] && return 1

        session_verify_csrf_token "$session_id" "$csrf_token"
        [[ $? != 0 ]] && return 1

        # nonexistant session
        session_get_csrf_token "1337"
        [[ $? == 0 ]] && return 1

        session_verify_csrf_token "1337" "$csrf_token"
        [[ $? == 0 ]] && return 1

        # wrong token
        session_verify_csrf_token "$session_id" "1337"
        [[ $? == 0 ]] && return 1

        return 0
    }
}

subtest_list=(
    session_csrf
)
