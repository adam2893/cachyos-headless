#!/bin/bash
# ============================================================
# start.sh — CachyOS Headless container entrypoint
# ============================================================
# Handles runtime configuration that cannot be done at build
# time: VNC password generation, DRI permissions, and env-var
# injection into supervisord.
# ============================================================
set -e

# ---- Export vars that supervisord.conf references ----
# These are consumed via %(ENV_…)s in supervisord.conf
export ENV_VNC_GEOMETRY="${RESOLUTION:-1920x1080}"
export ENV_VNC_DEPTH="${DEPTH:-24}"

# ---- Dynamic VNC password --------------------------------
# Overwrite the build-time passwd file whenever the PASSWD
# env var is set (or changed) at container start.
VNC_PASSWD_FILE="/home/${USER}/.vnc/passwd"
if [ -n "${PASSWD}" ]; then
    echo "${PASSWD}" | vncpasswd -f > "${VNC_PASSWD_FILE}"
    chmod 600 "${VNC_PASSWD_FILE}"
    chown "${USER}:${USER}" "${VNC_PASSWD_FILE}"
fi

# ---- Ownership -------------------------------------------
chown -R "${USER}:${USER}" "/home/${USER}"

# ---- Intel GPU device permissions -------------------------
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
fi

# ---- Stale VNC lock cleanup ------------------------------
# If the container was stopped ungracefully, stale lock/pid
# files will prevent VNC from starting.
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
rm -f "/home/${USER}/.vnc/*.pid" 2>/dev/null || true

# ---- Launch supervisord ----------------------------------
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
