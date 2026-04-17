#!/bin/bash
set -e

export VNC_GEOMETRY="${RESOLUTION:-1920x1080}"
export VNC_DEPTH="${DEPTH:-24}"

# Create .vnc directory if it doesn't exist (volume mount may hide build-time dirs)
mkdir -p "/home/${USER}/.vnc"
chown "${USER}:${USER}" "/home/${USER}/.vnc"

# Dynamic VNC password
VNC_PASSWD_FILE="/home/${USER}/.vnc/passwd"
if [ -n "${PASSWD}" ]; then
    echo "${PASSWD}" | vncpasswd -f > "${VNC_PASSWD_FILE}"
    chmod 600 "${VNC_PASSWD_FILE}"
    chown "${USER}:${USER}" "${VNC_PASSWD_FILE}"
fi

chown -R "${USER}:${USER}" "/home/${USER}"

# Intel GPU permissions
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
fi

# Stale VNC lock cleanup
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
rm -f "/home/${USER}/.vnc/*.pid" 2>/dev/null || true

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
