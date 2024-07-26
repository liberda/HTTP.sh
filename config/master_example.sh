declare -A cfg

cfg[ip]=127.0.0.1 # IP address to bind to - use 0.0.0.0 to bind to all

cfg[http]=true # enables/disables listening on HTTP
cfg[port]=1337 # HTTP port
cfg[socat_only]=false

cfg[namespace]='app'

cfg[root]='webroot/' 
cfg[index]='index.shs'
cfg[autoindex]=true

cfg[auth_required]=false
cfg[auth_realm]="Laura is cute <3"

cfg[ssl]=false # enables/disables listening on HTTPS
cfg[ssl_port]=8443
cfg[ssl_cert]=''
cfg[ssl_key]=''

cfg[extension]='shs'
cfg[extra_headers]='server: HTTP.sh/0.96 (devel)'

cfg[title]='HTTP.sh 0.96'

cfg[php_enabled]=false # enable PHP script evalutaion (requires PHP)
cfg[python_enabled]=false # enable Python script evalutaion (requires Python)

cfg[log]='log' # filename

# proxy functionality is very WiP
cfg[proxy]=false
cfg[proxy_url]='http://example.com/'

# mail handler config
cfg[mail]=""
cfg[mail_server]=""
cfg[mail_password]=""
cfg[mail_ssl]=true
cfg[mail_ignore_bad_cert]=false
