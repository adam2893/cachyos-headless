#!/usr/bin/env bash
###
# File: start-pipewire.sh
# Description: Start PipeWire audio server (pipewire daemon only)
#   WirePlumber and pipewire-pulse are managed as separate supervisor programs
###
source /usr/bin/common-functions.sh

# CATCH TERM SIGNAL:
_term() {
    kill -TERM "$pipewire_pid" 2>/dev/null
}
trap _term SIGTERM SIGINT

export XDG_RUNTIME_DIR="/run/user/${PUID:-1000}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export DISABLE_RTKIT=1

# Wait for the runtime dir
MAX=10
CT=0
while [ ! -d "${XDG_RUNTIME_DIR}" ]; do
    sleep 1
    CT=$(( CT + 1 ))
    if [ "$CT" -ge "$MAX" ]; then
        echo "FATAL: Gave up waiting for XDG_RUNTIME_DIR"
        exit 11
    fi
done

# Start the main PipeWire daemon
/usr/bin/pipewire &
pipewire_pid=$!

echo "PipeWire daemon started (PID: $pipewire_pid)"

# WAIT FOR CHILD PROCESS:
wait "$pipewire_pid"
