declare -A cfg

cfg[ip]=[::] # IP address to bind to - use [::] to bind to all

cfg[http]=true # enables/disables listening on HTTP
cfg[port]=1337 # HTTP port
cfg[socat_only]=false

cfg[namespace]='app'

cfg[root]='webroot/' 
cfg[index]='index.shs'
cfg[autoindex]=true

cfg[auth_required]=false
cfg[auth_realm]="asdf"

cfg[ssl]=false # enables/disables listening on HTTPS
cfg[ssl_port]=8443
cfg[ssl_cert]=''
cfg[ssl_key]=''

cfg[extension]='shs'
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
