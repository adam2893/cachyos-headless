#!/bin/bash
set -e

USER=${USER:-cachyos}
PUID=${PUID:-1000}
PASSWD=${PASSWD:-cachyos}
RESOLUTION=${RESOLUTION:-1920x1080}
DEPTH=${DEPTH:-24}

# ---- Directories ----
mkdir -p /home/${USER}/.config/tigervnc
mkdir -p /run/user/${PUID}
chown -R ${USER}:${USER} /home/${USER}
chown ${USER}:${USER} /run/user/${PUID}

# ---- VNC password ----
echo "${PASSWD}" | vncpasswd -f > /home/${USER}/.config/tigervnc/passwd
chmod 600 /home/${USER}/.config/tigervnc/passwd
chown ${USER}:${USER} /home/${USER}/.config/tigervnc/passwd

# ---- System D-Bus (PipeWire needs this) ----
mkdir -p /run/dbus
dbus-daemon --system --fork

# ---- PipeWire ----
export DISABLE_RTKIT=1
export XDG_RUNTIME_DIR="/run/user/${PUID}"
export PIPEWIRE_RUNTIME_DIR="/run/user/${PUID}"
export PULSE_RUNTIME_DIR="/run/user/${PUID}/pulse"

su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; export PIPEWIRE_RUNTIME_DIR=${PIPEWIRE_RUNTIME_DIR}; export DISABLE_RTKIT=1; pipewire" &
sleep 1
su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; export PIPEWIRE_RUNTIME_DIR=${PIPEWIRE_RUNTIME_DIR}; export DISABLE_RTKIT=1; wireplumber" &
sleep 1
su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; export PIPEWIRE_RUNTIME_DIR=${PIPEWIRE_RUNTIME_DIR}; export DISABLE_RTKIT=1; pipewire-pulse" &

# ---- GPU ----
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
fi

# ---- Clean stale locks ----
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
rm -f /home/${USER}/.config/tigervnc/*.pid /home/${USER}/.config/tigervnc/*.log 2>/dev/null || true
rm -f /home/${USER}/.vnc/*.pid /home/${USER}/.vnc/*.log 2>/dev/null || true

# ---- noVNC ----
/opt/noVNC-env/bin/websockify --web=/usr/share/novnc 8080 localhost:5901 &
sleep 1

# ---- Start Xvnc directly (bypass vncsession/vncserver) ----
# Xvnc is the actual X server — no systemd needed
su - ${USER} -c "Xvnc :1 -desktop CachyOS -geometry ${RESOLUTION} -depth ${DEPTH} -rfbauth /home/${USER}/.config/tigervnc/passwd -rfbport 5901 -localhost no -SecurityTypes VncAuth &"

# ---- Wait for X server ----
sleep 3

# ---- Start XFCE ----
su - ${USER} -c "DISPLAY=:1 startxfce4" &

# ---- Keep container alive ----
wait -n
