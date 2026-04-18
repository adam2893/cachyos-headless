#!/bin/bash
###
# File: start.sh (entrypoint)
# Description: CachyOS Headless container entrypoint
#   Executes cont-init.d scripts for runtime configuration,
#   then hands off to supervisord for service management.
# Adapted from Steam-Headless/docker-steam-headless
###
set -e

USER=${USER:-cachyos}
PUID=${PUID:-1000}
PGID=${PGID:-1000}
PASSWD=${PASSWD:-cachyos}
HOME=${HOME:-/home/cachyos}
DISPLAY=${DISPLAY:-:1}
RESOLUTION=${RESOLUTION:-1920x1080}
DEPTH=${DEPTH:-24}
PORT_VNC=${PORT_VNC:-5901}
PORT_NOVNC_WEB=${PORT_NOVNC_WEB:-8080}
ENABLE_STEAM=${ENABLE_STEAM:-true}
ENABLE_SUNSHINE=${ENABLE_SUNSHINE:-true}
FORCE_X11_DUMMY_CONFIG=${FORCE_X11_DUMMY_CONFIG:-true}

# Export all env vars so supervisord can pass them to child processes
export USER PUID PGID PASSWD HOME DISPLAY RESOLUTION DEPTH
export PORT_VNC PORT_NOVNC_WEB ENABLE_STEAM ENABLE_SUNSHINE
export FORCE_X11_DUMMY_CONFIG

# === AGGRESSIVE CLEANUP ===
echo "=== Cleaning stale runtime files ==="
rm -f /run/dbus/pid /run/dbus/system_bus_socket /run/dbus/messagebus.pid
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* /tmp/.ICE-unix/*
rm -f /tmp/.started-desktop /tmp/.dbus-desktop-session.env /tmp/.gpu-env
rm -rf /run/user/${PUID}/* 2>/dev/null || true

mkdir -p /run/dbus /run/user/${PUID} /tmp/.X11-unix /tmp/.ICE-unix
chmod 1777 /tmp/.X11-unix /tmp/.ICE-unix
chown ${USER}:${USER} /run/user/${PUID}

# === Execute all container init scripts ===
echo ""
echo "=========================================="
echo "  CachyOS Headless - Runtime Init"
echo "=========================================="
echo ""

for init_script in /etc/cont-init.d/*.sh ; do
    if [ -f "${init_script}" ]; then
        echo -e "\e[34m[ ${init_script}: executing... ]\e[0m"
        sed -i 's/\r$//' "${init_script}"
        source "${init_script}"
    fi
done
touch /tmp/.first-run-init-scripts

# === Create supervisor log directory ===
mkdir -p /var/log/supervisor

# === Start supervisord ===
echo ""
echo -e "\e[35m**** Starting supervisord ****\e[0m"
echo ""
exec /usr/bin/supervisord -c /etc/supervisord.conf --nodaemon --user root
