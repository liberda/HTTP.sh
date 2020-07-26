declare -A cfg

cfg[port]=1337

cfg[root]='webroot/'
cfg[index]='index.shs'
cfg[autoindex]=true

cfg[auth_required]=false
cfg[auth_realm]="Laura is cute <3"

cfg[ssl]=false
cfg[ssl_port]=8443
cfg[ssl_cert]=''
cfg[ssl_key]=''

cfg[extension]='shs'
cfg[extra_headers]='server: HTTP.sh/0.91 (devel)'

cfg[title]='ddd defies development'

cfg[php_enabled]=false
cfg[python_enabled]=false

# by default, those logs are placed in the main directory - change it to /var/log/_name_ for production
cfg[log_http]='log_http'
cfg[log_https]='log_https'
cfg[log_misc]='log'

cfg[proxy]=false
cfg[proxy_url]='http://example.com/'