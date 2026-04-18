#!/usr/bin/env bash
###
# File: start-sunshine.sh
# Description: Start Sunshine game streaming server
# Adapted from Steam-Headless/docker-steam-headless
###
set -e
source /usr/bin/common-functions.sh

# CATCH TERM SIGNAL:
_term() {
    kill -INT "$sunshine_pid" 2>/dev/null
    sleep 0.5
    counter=0
    while kill -0 "$sunshine_pid"; do
        kill -TERM "$sunshine_pid" 2>/dev/null
        counter=$((counter + 1))
        [ "$counter" -gt 8 ] && break
        sleep 0.5
    done
    counter=0
    while kill -0 "$sunshine_pid"; do
        kill -KILL "$sunshine_pid" 2>/dev/null
        counter=$((counter + 1))
        [ "$counter" -gt 4 ] && break
        sleep 0.5
    done
}
trap _term SIGTERM SIGINT

# CONFIGURE:
# Install default configurations
mkdir -p "${HOME:?}/.config/sunshine"
if [ ! -f "${HOME:?}/.config/sunshine/sunshine.conf" ]; then
    cp -vf /templates/sunshine/sunshine.conf "${HOME:?}/.config/sunshine/sunshine.conf"
fi
if [ ! -f "${HOME:?}/.config/sunshine/apps.json" ]; then
    cp -vf /templates/sunshine/apps.json "${HOME:?}/.config/sunshine/apps.json"
fi
if [ ! -f "${HOME:?}/.config/sunshine/sunshine_state.json" ]; then
    echo "{}" > "${HOME:?}/.config/sunshine/sunshine_state.json"
fi

# Reset the default username/password if configured
if ([ "X${SUNSHINE_USER:-}" != "X" ] && [ "X${SUNSHINE_PASS:-}" != "X" ]); then
    /usr/bin/sunshine --creds "${SUNSHINE_USER:?}" "${SUNSHINE_PASS:?}" 2>/dev/null || true
fi

# EXECUTE PROCESS:
# Wait for the X server to start
wait_for_x

# Start a session bus instance of dbus-daemon
wait_for_desktop_dbus_session
export_desktop_dbus_session

# Wait for the desktop to start
wait_for_desktop

# Start the sunshine server
/usr/bin/sunshine "${HOME:?}/.config/sunshine/sunshine.conf" &
sunshine_pid=$!

echo "Sunshine started"

# WAIT FOR CHILD PROCESS:
wait "$sunshine_pid"
