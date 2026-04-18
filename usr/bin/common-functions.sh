#!/usr/bin/env bash
###
# File: common-functions.sh
# Description: Helper functions for CachyOS Headless (adapted from Steam-Headless)
###

# Wait for X server to start
wait_for_x() {
    MAX=60
    CT=0
    while ! xdpyinfo >/dev/null 2>&1; do
        sleep 0.50s
        CT=$(( CT + 1 ))
        if [ "$CT" -ge "$MAX" ]; then
            echo "FATAL: Gave up waiting for X server $DISPLAY"
            exit 11
        fi
    done
    echo "X server is ready on $DISPLAY"
}

# Wait for desktop to start
wait_for_desktop() {
    MAX=30
    CT=0
    while [ ! -f /tmp/.started-desktop ]; do
        sleep 1
        CT=$(( CT + 1 ))
        if [ "$CT" -ge "$MAX" ]; then
            echo "FATAL: Gave up waiting for Desktop to start"
            exit 11
        fi
    done
    echo "Desktop is ready"
}

# Export desktop dbus session
export_desktop_dbus_session() {
    if [ ! -f /tmp/.dbus-desktop-session.env ]; then
        echo "$(dbus-launch)" > /tmp/.dbus-desktop-session.env
    fi
    export $(cat /tmp/.dbus-desktop-session.env)
}

# Wait for desktop dbus session to start
wait_for_desktop_dbus_session() {
    MAX=10
    CT=0
    while [ ! -f /tmp/.dbus-desktop-session.env ]; do
        sleep 1
        CT=$(( CT + 1 ))
        if [ "$CT" -ge "$MAX" ]; then
            echo "FATAL: Gave up waiting for Desktop dbus-launch session"
            exit 11
        fi
    done
}

# Print colored headers
print_header() {
    echo -e "\e[35m**** ${@} ****\e[0m"
}

print_step() {
    echo -e "\e[36m  - ${@}\e[0m"
}

print_warning() {
    echo -e "\e[33mWARNING: ${@}\e[0m"
}

print_error() {
    echo -e "\e[31mERROR: ${@}\e[0m"
}
