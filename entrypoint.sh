#!/bin/bash
# Wrapper entrypoint for the mtproto-proxy image.
# Starts the internal stats server (private network only) in the
# background, then starts the proxy exactly as the official image does.
( while true; do perl /usr/local/bin/stats_server.pl; sleep 5; done ) &
exec /bin/bash /run.sh
