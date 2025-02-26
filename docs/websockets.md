# HTTP.sh and WebSockets

WebSocket support is currently experimental; It has been rewritten from scratch and verified, but
it's a bit rough around the edges. Additionally, you have to manually obtain a copy of libsh
before using websockets:

    git clone https://git.sakamoto.pl/domi/libsh src/libsh

Afterwards, you need to set `cfg[websocket_enable]` to `true` and optionally customize
`cfg[extension_websocket]`. Both of those options can be found in `config/master.sh`.

It is **required** that all of your websocket handling scripts have a different extension than
your normal scripts. By default that's set to `shx` (opposed to default `shs` for normal scripts).
The way of interfacing with WebSockets is fundamentally different enough that it warrants wrapper
functions. While one could create scripts compatible with both, in most cases executing a script
with the wrong interface is NOT what we want to happen.

## The API

`ws.sh` exposes two main functions: `ws_recv` and `ws_send`. An example use is presented below:

    #!/bin/bash
    while ws_recv; do
    	ws_send "hiii! here's your message: $ws_res"
    done

### ws_recv

`ws_recv` waits for a new message, parses and unmasks it, then puts it into `$ws_res`.
This variable name can be overriden by doing `ws_recv varname`, which will then use `$varname` for
the payload.

The return codes are:
- 0 for successful read
- 1 if EOF is encountered (analogous to builtin `read`)

### ws_send

`ws_send <payload>` generates a header and sends the message out.

## Note about async I/O

Waiting for a message to arrive before sending out our data is not always useful. Thus, some use of
asynchronous I/O is in order. Bash doesn't make this very easy, but it's not impossible:

    #!/bin/bash
    {
    	while sleep 1; do
    		ws_send "a"
    	done
    } &
    
    while ws_recv; do
    	ws_send "$ws_res"
    done
    
    pkill -P $$

This spawns a subshell which sends the letter "a". Then, we create a receive loop where we echo
everything back. Finally, and most importantly, when that receive loop quits, we kill all children
of the current shell process, cleaning up the previous subshell. IF THIS ISN'T DONE, BAD THINGS
HAPPEN TO YOUR SERVER - especially if your loop *doesn't* include a sleep like the example.

With this style of async I/O, you have to take care of the IPC yourself. That is, no variables are
shared after the subshell spawns. The best way to handle this is to fully decouple the input and
output; If that's impossible, you may use a file approach (with or without notORM).

## Quirks

- Currently, anything manually sent to stdout will mangle the bitstream,
  causing all subsequent I/O to fail.
- Endless loops are dangerous if not cleaned up correctly at the end of the file!
  Additionally, you **need** a receive loop (it can be a dummy, with `:`) if you want to continously
  send and cleanup after the connection closes; Otherwise there's nothing indicating whether the
  connection is still alive or not.
- There's no way to transmit binary data w/o mangling it. TODO.
