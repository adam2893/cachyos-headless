#!/usr/bin/env bash
###
# File: start-pipewire.sh
# Description: Start PipeWire audio server
###
set -e
source /usr/bin/common-functions.sh

# CATCH TERM SIGNAL:
_term() {
    kill -TERM "$pipewire_pid" 2>/dev/null
}
trap _term SIGTERM SIGINT

# EXECUTE PROCESS:
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

/usr/bin/pipewire -c pipewire-pulse.conf &
pipewire_pid=$!

echo "PipeWire started"

# WAIT FOR CHILD PROCESS:
wait "$pipewire_pid"
