declare -A cfg

cfg[ip]=[::] # IP address to bind to - use [::] to bind to all
cfg[port]=1337 # HTTP port

cfg[namespace]='app'

cfg[root]='webroot/' 
cfg[index]='index.shs'
cfg[autoindex]=true

cfg[auth_required]=false
cfg[auth_realm]="asdf"

cfg[extension]='shs'
cfg[extension_websocket]='shx'
#cfg[encoding]='UTF-8' # UTF-8 by default, used by iconv
cfg[extra_headers]="server: HTTP.sh/$HTTPSH_VERSION (devel)"

cfg[title]="HTTP.sh $HTTPSH_VERSION"

cfg[log]='log' # filename

# mail handler config
cfg[mail]=""
cfg[mail_server]=""
cfg[mail_password]=""
cfg[mail_ssl]=true
cfg[mail_ignore_bad_cert]=false

# unset for legacy sha256sum hashing (not recommended)
cfg[hash]="argon2id"

cfg[cookie_path]="/"

# should registering automatically login the user?
# useful for flows involving a confirmation e-mail
cfg[register_should_login]=true

cfg[websocket_enable]=false

# should notORM always try to retrieve records to an associative array?
# disabled by default for legacy compat
cfg[notORM_always_assoc]=false

cfg[template_date_format]='%Y-%m-%d %H:%M:%S'

# should we warn you about breaking changes in HTTP.sh?
# true by default, set false to disable
cfg[error_on_breaking_changes]=true

# how long should we wait before timing out on reading the first few bytes?
# cfg[wait_for_initial_read]=30
