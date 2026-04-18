#!/usr/bin/env bash
###
# File: start-x11vnc.sh
# Description: Start x11vnc to share the Xorg display over VNC
# Adapted from Steam-Headless/docker-steam-headless
###
set -e
source /usr/bin/common-functions.sh

# CATCH TERM SIGNAL:
_term() {
    kill -TERM "$x11vnc_pid" 2>/dev/null
}
trap _term SIGTERM SIGINT

# EXECUTE PROCESS:
# Wait for the X server to start
wait_for_x

# Start the x11vnc server
/usr/bin/x11vnc \
    -display "${DISPLAY}" \
    -rfbport "${PORT_VNC:-5901}" \
    -shared \
    -forever \
    -nopw &
x11vnc_pid=$!

echo "x11vnc started on port ${PORT_VNC:-5901}"

# WAIT FOR CHILD PROCESS:
wait "$x11vnc_pid"
