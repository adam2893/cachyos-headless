#!/usr/bin/env bash
###
# File: 60-configure_xorg.sh
# Description: Configure Xorg server for headless operation
# Adapted from Steam-Headless/docker-steam-headless
###
source /usr/bin/common-functions.sh

print_header "Configure Xorg"

# Allow anybody to run X server
if [[ ! -f /etc/X11/Xwrapper.config ]]; then
    print_step "Create Xwrapper.config"
    echo 'allowed_users=anybody' > /etc/X11/Xwrapper.config
    echo 'needs_root_rights=yes' >> /etc/X11/Xwrapper.config
elif grep -Fxq "allowed_users=console" /etc/X11/Xwrapper.config; then
    print_step "Configure Xwrapper.config"
    sed -i "s/allowed_users=console/allowed_users=anybody/" /etc/X11/Xwrapper.config
    echo 'needs_root_rights=yes' >> /etc/X11/Xwrapper.config
fi

# Remove previous Xorg config
rm -f /etc/X11/xorg.conf

# Ensure the X socket path exists
mkdir -p /tmp/.X11-unix

# Clear out old lock files
display_num="${DISPLAY#:}"
display_file="/tmp/.X11-unix/X${display_num}"
if [ -S "${display_file}" ]; then
    print_step "Removing ${display_file} before starting"
    rm -f "/tmp/.X${display_num}-lock"
    rm "${display_file}"
fi

# Ensure X-windows session path is owned by root
mkdir -p /tmp/.ICE-unix
chown root:root /tmp/.ICE-unix/
chmod 1777 /tmp/.ICE-unix/

# Check if a monitor is connected
monitor_connected=$(cat /sys/class/drm/card*/status 2>/dev/null | awk '/^connected/ { print $1; }' | head -n1)

# If no monitor is connected, use dummy xorg config
if ([ -z "${monitor_connected}" ] || [ "${FORCE_X11_DUMMY_CONFIG:-false}" = "true" ]); then
    print_step "No monitors connected. Installing dummy xorg.conf"
    cp -f /templates/xorg/xorg.dummy.conf /etc/X11/xorg.conf
    
    # Generate modeline for the configured resolution
    if [ -n "${RESOLUTION:-}" ]; then
        mode_w=$(echo "${RESOLUTION}" | cut -d'x' -f1)
        mode_h=$(echo "${RESOLUTION}" | cut -d'x' -f2)
        if [ -n "${mode_w}" ] && [ -n "${mode_h}" ]; then
            modeline=$(cvt -r "${mode_w}" "${mode_h}" 60 | sed -n 2p)
            if [ -n "${modeline}" ]; then
                print_step "Adding modeline for ${RESOLUTION}"
                # Replace the default 1920x1080 modeline with the configured resolution
                sed -i "s|ModeLine.*1920x1080.*|    ${modeline}|" /etc/X11/xorg.conf
                # Update the Modes line
                sed -i "s|Modes.*\"1920x1080\".*|        Modes           \"${RESOLUTION}\"|" /etc/X11/xorg.conf
            fi
        fi
    fi
else
    print_step "Monitor connected, using auto-detected Xorg configuration"
fi

# GPU permissions
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
    print_step "GPU device permissions configured"
fi

echo -e "\e[34mDONE\e[0m"
