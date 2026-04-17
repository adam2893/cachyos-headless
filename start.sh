#!/bin/bash
set -e

export VNC_GEOMETRY="${RESOLUTION:-1920x1080}"
export VNC_DEPTH="${DEPTH:-24}"

# --- Create required directories ---
mkdir -p "/home/${USER}/.vnc"
mkdir -p "/run/user/${PUID}"
chown -R "${USER}:${USER}" "/home/${USER}"
chown "${USER}:${USER}" "/run/user/${PUID}"

# --- VNC password ---
VNC_PASSWD_FILE="/home/${USER}/.vnc/passwd"
if [ -n "${PASSWD}" ]; then
    echo "${PASSWD}" | vncpasswd -f > "${VNC_PASSWD_FILE}"
    chmod 600 "${VNC_PASSWD_FILE}"
    chown "${USER}:${USER}" "${VNC_PASSWD_FILE}"
fi

# --- Runtime environment ---
export XDG_RUNTIME_DIR="/run/user/${PUID}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# --- Start D-Bus user session (as the user, not root) ---
su - "${USER}" -c "dbus-daemon --session --fork --address=${DBUS_SESSION_BUS_ADDRESS}"

# --- GPU permissions ---
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
fi

# --- Stale VNC locks ---
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
rm -f "/home/${USER}/.vnc/*.pid" 2>/dev/null || true
rm -f "/home/${USER}/.vnc/*.log" 2>/dev/null || true

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
