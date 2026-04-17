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

# === GPU / Arc B580 - MOVED EARLY BEFORE Xvnc ===
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
    echo "=== GPU devices permissions fixed ==="
fi

export LIBVA_DRIVER_NAME=iHD
export MESA_LOADER_DRIVER_OVERRIDE=iris
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
export __GLX_VENDOR_LIBRARY_NAME=mesa
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_LOADER_DRIVER_OVERRIDE=iris   # double for safety
echo "=== Arc B580 GPU env set (iHD + iris) ==="

# === PipeWire stack ===
su - ${USER} -c "
    export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}
    export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}
    export DISABLE_RTKIT=1
    pipewire
" &
sleep 1.5

su - ${USER} -c "
    export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}
    export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}
    export DISABLE_RTKIT=1
    wireplumber
" &
sleep 1

su - ${USER} -c "
    export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}
    export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}
    export DISABLE_RTKIT=1
    pipewire-pulse
" &
sleep 1

# === noVNC ===
/opt/noVNC-env/bin/websockify --web=/usr/share/novnc 8080 localhost:5901 &
sleep 1

# === Xvnc with GLX (now after GPU setup) ===
su - ${USER} -c "Xvnc :1 -desktop CachyOS -geometry ${RESOLUTION} -depth ${DEPTH} \
    -rfbauth /home/${USER}/.config/tigervnc/passwd -rfbport 5901 \
    -localhost no -SecurityTypes VncAuth -extension GLX &"
sleep 4

# === XFCE desktop (single launch) ===
su - ${USER} -c "DISPLAY=:1 DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS} startxfce4" &

# Keep container alive
wait -n
