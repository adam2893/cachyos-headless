#!/bin/bash
set -e

USER=${USER:-cachyos}
PUID=${PUID:-1000}
PASSWD=${PASSWD:-cachyos}
RESOLUTION=${RESOLUTION:-1920x1080}
DEPTH=${DEPTH:-24}

# ---- Create directories ----
mkdir -p /home/${USER}/.config/tigervnc
mkdir -p /run/user/${PUID}
chown -R ${USER}:${USER} /home/${USER}
chown ${USER}:${USER} /run/user/${PUID}

# ---- VNC password (new path) ----
echo "${PASSWD}" | vncpasswd -f > /home/${USER}/.config/tigervnc/passwd
chmod 600 /home/${USER}/.config/tigervnc/passwd
chown ${USER}:${USER} /home/${USER}/.config/tigervnc/passwd

# ---- VNC config ----
cat > /home/${USER}/.config/tigervnc/vncserver-config-defaults << CONF
geometry=${RESOLUTION}
depth=${DEPTH}
localhost=no
CONF
chown ${USER}:${USER} /home/${USER}/.config/tigervnc/vncserver-config-defaults

# ---- XFCE startup (new path) ----
cat > /home/${USER}/.config/tigervnc/Xvnc-session << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
exec startxfce4
EOF
chmod +x /home/${USER}/.config/tigervnc/Xvnc-session
chown ${USER}:${USER} /home/${USER}/.config/tigervnc/Xvnc-session

# ---- Runtime env ----
export XDG_RUNTIME_DIR="/run/user/${PUID}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# ---- D-Bus ----
su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}; dbus-daemon --session --fork --address=${DBUS_SESSION_BUS_ADDRESS}"

# ---- GPU ----
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
fi

# ---- Clean stale locks ----
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
rm -f /home/${USER}/.config/tigervnc/*.pid /home/${USER}/.config/tigervnc/*.log
rm -f /home/${USER}/.vnc/*.pid /home/${USER}/.vnc/*.log 2>/dev/null || true

# ---- PipeWire (background) ----
su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; pipewire" &
sleep 1
su - ${USER} -c "export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}; wireplumber" &

# ---- noVNC (background) ----
/opt/noVNC-env/bin/websockify --web=/usr/share/novnc 8080 localhost:5901 &
sleep 1

# ---- Start VNC via script file (avoids su -c quoting issues) ----
cat > /tmp/start-vnc.sh << 'EOF'
#!/bin/bash
cd
exec vncsession :1
EOF
chmod +x /tmp/start-vnc.sh
chown ${USER}:${USER} /tmp/start-vnc.sh

exec su - ${USER} -c /tmp/start-vnc.sh
