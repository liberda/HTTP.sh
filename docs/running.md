# Running http.sh 

## cli args

The arg parsing is a bit rudimentary atm. Assume only one option supported per invocation.

- `init` creates an app skeleton and writes example config. Optional second parameter sets the
  namespace (app directory) name.
- `debug` shows stderr (useful for debugging)
- `debuggier` shows stderr and calltrace 
- `shell` drops you into an environment practically equivalent to the runtime
- `utils` lists all available [utilities](./util.md) (scripts which integrate into the
  standard HTTP.sh environment, but are strictly for CLI use. Useful for administrative tasks.)
- `<util> [params]` launches an utility, if it's available
