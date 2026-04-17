#!/bin/bash
export XDG_RUNTIME_DIR="/run/user/1000"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export DISPLAY=:1
exec vncserver :1 -geometry "${VNC_GEOMETRY:-1920x1080}" -depth "${VNC_DEPTH:-24}" -localhost no -rfbauth /home/cachyos/.vnc/passwd
