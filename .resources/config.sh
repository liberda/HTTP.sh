## app config
## your application-specific config goes here!

# worker_add example 5
cfg[enable_multipart]=false # by default, uploading files is disabled

if [[ "$run_once" ]]; then
	# the following will only run once at startup, not with every request
	:
fi

## overrides the default include path for templates
## searches paths in order until it finds a file
# template_relative_paths=(
# 	"${cfg[namespace]}/template/"
# )
