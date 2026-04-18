#!/usr/bin/env bash
###
# File: 80-configure_flatpak.sh
# Description: Configure Flatpak remotes
# Adapted from Steam-Headless/docker-steam-headless
###
source /usr/bin/common-functions.sh

print_header "Configure Flatpak"

# Add flathub remote at system level
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Add flathub remote at user level
su - "${USER}" -c "flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo" 2>/dev/null || true

echo -e "\e[34mDONE\e[0m"
