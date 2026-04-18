#!/bin/bash
set -e

USER=${USER:-cachyos}
PUID=${PUID:-1000}
PASSWD=${PASSWD:-cachyos}
RESOLUTION=${RESOLUTION:-1920x1080}
DEPTH=${DEPTH:-24}

# === AGGRESSIVE CLEANUP ===
echo "=== Cleaning stale runtime files ==="
rm -f /run/dbus/pid /run/dbus/system_bus_socket /run/dbus/messagebus.pid
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 /tmp/.X*-lock
rm -rf /tmp/.X11-unix/* /tmp/.ICE-unix/*
rm -f /run/user/${PUID}/* 2>/dev/null || true

mkdir -p /run/dbus /run/user/${PUID} /tmp/.X11-unix /tmp/.ICE-unix
chmod 1777 /tmp/.X11-unix /tmp/.ICE-unix
chown ${USER}:${USER} /run/user/${PUID}

# === machine-id ===
if [ ! -f /etc/machine-id ]; then
    dbus-uuidgen --ensure=/etc/machine-id
fi
if [ ! -f /var/lib/dbus/machine-id ]; then
    mkdir -p /var/lib/dbus
    cp /etc/machine-id /var/lib/dbus/machine-id
fi

# === Directories + VNC password ===
mkdir -p /home/${USER}/.config/tigervnc
chown -R ${USER}:${USER} /home/${USER}
echo "${PASSWD}" | vncpasswd -f > /home/${USER}/.config/tigervnc/passwd
chmod 600 /home/${USER}/.config/tigervnc/passwd
chown ${USER}:${USER} /home/${USER}/.config/tigervnc/passwd

# === System D-Bus ===
mkdir -p /run/dbus
dbus-daemon --system --fork

# === User session D-Bus ===
export XDG_RUNTIME_DIR="/run/user/${PUID}"
mkdir -p "${XDG_RUNTIME_DIR}"
chown ${USER}:${USER} "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"
DBUS_SESSION_BUS_ADDRESS=$(su - ${USER} -c "dbus-daemon --session --fork --print-address")
export DBUS_SESSION_BUS_ADDRESS
echo "=== User D-Bus started at ${DBUS_SESSION_BUS_ADDRESS} ==="

# === GPU permissions ===
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
    echo "=== GPU devices permissions fixed ==="
fi

# === Install Sunshine flatpak at runtime (requires D-Bus) ===
if ! su - ${USER} -c "flatpak --user list 2>/dev/null | grep -q sunshine" 2>/dev/null; then
    echo "=== Installing Sunshine flatpak (first boot) ==="
    su - ${USER} -c "flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" 2>/dev/null || true
    su - ${USER} -c "flatpak --user install -y flathub dev.lizardbyte.app.Sunshine" 2>/dev/null || echo "=== WARNING: Sunshine flatpak install failed, will retry next boot ==="
    echo "=== Sunshine flatpak install done ==="
else
    echo "=== Sunshine flatpak already installed ==="
fi

# === Export env vars for supervisord child processes ===
export RESOLUTION
export DEPTH

# === Launch supervisord (manages VNC, XFCE, PipeWire, noVNC) ===
echo "=== Starting supervisord ==="
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
