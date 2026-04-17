#!/bin/bash
set -e

# ---- Setup directories ----
mkdir -p /home/${USER}/.vnc /run/user/${PUID}
chown -R ${USER}:${USER} /home/${USER} /run/user/${PUID}

# ---- VNC password ----
echo "${PASSWD}" | vncpasswd -f > /home/${USER}/.vnc/passwd
chmod 600 /home/${USER}/.vnc/passwd
chown ${USER}:${USER} /home/${USER}/.vnc/passwd

# ---- Write xstartup with proper env vars ----
cat > /home/${USER}/.vnc/xstartup << XSTARTUP_EOF
#!/bin/bash
export XDG_RUNTIME_DIR="/run/user/${PUID}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${PUID}/bus"
unset SESSION_MANAGER
exec startxfce4
XSTARTUP_EOF
chmod +x /home/${USER}/.vnc/xstartup
chown ${USER}:${USER} /home/${USER}/.vnc/xstartup

# ---- Runtime environment ----
export XDG_RUNTIME_DIR="/run/user/${PUID}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# ---- Start D-Bus user session ----
su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}; dbus-daemon --session --fork --address=${DBUS_SESSION_BUS_ADDRESS}"

# ---- Start PipeWire (background) ----
su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}; pipewire -c pipewire-pulse.conf" &
sleep 1
su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}; wireplumber" &

# ---- GPU permissions ----
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
fi

# ---- Clean stale VNC locks ----
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
rm -f /home/${USER}/.vnc/*.pid /home/${USER}/.vnc/*.log

# ---- Start noVNC (background) ----
/opt/noVNC-env/bin/websockify --web=/usr/share/novnc 8080 localhost:5901 &
sleep 1

# ---- Start VNC (foreground, keeps container alive) ----
# vncserver runs xstartup automatically, which starts XFCE
exec su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}; vncserver :1 -geometry ${RESOLUTION:-1920x1080} -depth ${DEPTH:-24} -localhost no -rfbauth /home/${USER}/.vnc/passwd -fg"
