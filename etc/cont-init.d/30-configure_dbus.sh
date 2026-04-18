#!/usr/bin/env bash
###
# File: 30-configure_dbus.sh
# Description: Configure system D-Bus
###
source /usr/bin/common-functions.sh

print_header "Configure D-Bus"

# Machine-id
if [ ! -f /etc/machine-id ]; then
    dbus-uuidgen --ensure=/etc/machine-id
fi
if [ ! -f /var/lib/dbus/machine-id ]; then
    mkdir -p /var/lib/dbus
    cp /etc/machine-id /var/lib/dbus/machine-id
fi

# Start system D-Bus
mkdir -p /run/dbus
rm -f /run/dbus/pid /run/dbus/system_bus_socket
dbus-daemon --system --fork

# Wait for D-Bus to be ready
sleep 1
if [ -S /run/dbus/system_bus_socket ]; then
    print_step "System D-Bus started"
else
    print_error "Failed to start system D-Bus"
fi

# Setup user runtime directory
export XDG_RUNTIME_DIR="/run/user/${PUID}"
mkdir -p "${XDG_RUNTIME_DIR}"
chown "${USER}":"${USER}" "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

echo -e "\e[34mDONE\e[0m"
