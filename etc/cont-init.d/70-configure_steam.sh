#!/usr/bin/env bash
###
# File: 70-configure_steam.sh
# Description: Configure Steam autostart
# Adapted from Steam-Headless/docker-steam-headless
###
source /usr/bin/common-functions.sh

print_header "Configure Steam"

# Create Steam autostart desktop entry
steam_autostart_desktop="$(
    cat <<EOF
[Desktop Entry]
Type=Application
Exec=gamemoderun steam -bigpicture -silent -no-cef-sandbox
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Steam
EOF
)"

if [ "${ENABLE_STEAM:-true}" = "true" ]; then
    print_step "Enabling Steam autostart"
    echo "${steam_autostart_desktop}" > "${HOME}/.config/autostart/steam.desktop"
    chown "${USER}":"${USER}" "${HOME}/.config/autostart/steam.desktop"
else
    print_step "Disabling Steam autostart"
    rm -f "${HOME}/.config/autostart/steam.desktop"
fi

echo -e "\e[34mDONE\e[0m"
