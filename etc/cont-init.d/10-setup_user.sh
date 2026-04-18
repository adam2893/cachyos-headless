#!/usr/bin/env bash
###
# File: 10-setup_user.sh
# Description: Configure user, groups, and permissions
###
source /usr/bin/common-functions.sh

print_header "Configure user"

# Ensure user groups exist
for group in audio video wheel; do
    getent group "$group" >/dev/null 2>&1 || groupadd "$group"
done

# Create user if it doesn't exist
if ! id -u "${USER}" >/dev/null 2>&1; then
    print_step "Creating user ${USER} with UID ${PUID}"
    groupadd -g "${PGID}" "${USER}" 2>/dev/null || true
    useradd -m -u "${PUID}" -g "${PGID}" -G audio,video,wheel -s /bin/bash "${USER}"
fi

# Set password
echo "${USER}:${PASSWD}" | chpasswd

# Configure sudo
echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"${USER}"
chmod 440 /etc/sudoers.d/"${USER}"

# Ensure home directory exists and is owned by user
mkdir -p "${HOME}"
chown -R "${USER}":"${USER}" "${HOME}"

# Create required directories
mkdir -p "${HOME}/.config/autostart"
mkdir -p "${HOME}/.config/sunshine"
mkdir -p "${HOME}/.cache/log"
chown -R "${USER}":"${USER}" "${HOME}/.config" "${HOME}/.cache"

echo -e "\e[34mDONE\e[0m"
