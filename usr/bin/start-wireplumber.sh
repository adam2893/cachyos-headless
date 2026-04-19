#!/usr/bin/env bash
###
# File: start-wireplumber.sh
# Description: Start WirePlumber session manager for PipeWire
###
source /usr/bin/common-functions.sh

_term() {
    kill -TERM "$wp_pid" 2>/dev/null
}
trap _term SIGTERM SIGINT

export XDG_RUNTIME_DIR="/run/user/${PUID:-1000}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export DISABLE_RTKIT=1

# Wait for PipeWire daemon to be ready
wait_for_pipewire

# Start WirePlumber
/usr/bin/wireplumber &
wp_pid=$!

echo "WirePlumber started (PID: $wp_pid)"

wait "$wp_pid"
