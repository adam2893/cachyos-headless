#!/usr/bin/env bash
###
# File: start-pipewire-pulse.sh
# Description: Start PipeWire-Pulse (PulseAudio compatibility layer)
#   This is what Steam and other apps connect to for audio
###
source /usr/bin/common-functions.sh

_term() {
    kill -TERM "$pwp_pid" 2>/dev/null
}
trap _term SIGTERM SIGINT

export XDG_RUNTIME_DIR="/run/user/${PUID:-1000}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export DISABLE_RTKIT=1

# Wait for PipeWire daemon to be ready
wait_for_pipewire

# Start pipewire-pulse (PulseAudio bridge)
/usr/bin/pipewire -c pipewire-pulse.conf &
pwp_pid=$!

echo "PipeWire-Pulse started (PID: $pwp_pid)"

wait "$pwp_pid"
