#!/usr/bin/env bash
###
# File: start-desktop.sh
# Description: Start XFCE4 desktop environment after X is ready
# Adapted from Steam-Headless/docker-steam-headless
###
set -e
source /usr/bin/common-functions.sh

# CATCH TERM SIGNAL:
_term() {
    kill -TERM "$desktop_pid" 2>/dev/null
}
trap _term SIGTERM SIGINT

# CONFIGURE:
# Remove lockfiles
rm -f /tmp/.started-desktop

# Start a session bus instance of dbus-daemon
rm -fv /tmp/.dbus-desktop-session.env
export_desktop_dbus_session

# Configure XDG environment variables
export XDG_CACHE_HOME="${HOME:?}/.cache"
export XDG_CONFIG_HOME="${HOME:?}/.config"
export XDG_DATA_HOME="${HOME:?}/.local/share"

# EXECUTE PROCESS:
# Wait for the X server to start
wait_for_x

# Run the desktop environment
echo "**** Starting XFCE4 ****"
/usr/bin/startxfce4 &
desktop_pid=$!
touch /tmp/.started-desktop

# WAIT FOR CHILD PROCESS:
wait "$desktop_pid"
