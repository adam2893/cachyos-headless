#!/bin/bash
export XDG_RUNTIME_DIR="/run/user/1000"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export DISPLAY=:1
export DISABLE_RTKIT=1
exec pipewire -c pipewire-pulse.conf
