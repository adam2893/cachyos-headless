FROM cachyos/cachyos-v3:latest

ENV USER=cachyos \
    PASSWD=cachyos \
    HOME=/home/cachyos \
    DISPLAY=:1 \
    RESOLUTION=1920x1080 \
    DEPTH=24 \
    TERM=xterm \
    PUID=1000 \
    PGID=1000

# ---- Init pacman & full system update + enable multilib for Steam ----
RUN echo "=== [1/19] Init pacman & update + multilib ===" && \
    pacman-key --init && \
    pacman-key --populate archlinux cachyos && \
    pacman -Sy --noconfirm archlinux-keyring cachyos-keyring && \
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    pacman -Syu --noconfirm && \
    echo "=== [1/19] DONE ==="

# ---- 2-12: Keep ALL your original XFCE / VNC / audio / utils steps exactly the same ----
# (copy-paste your original steps 2 through 12 here — I'm not repeating them to save space)

# ---- 13: GPU (keep yours + mesa-utils for future testing) ----
RUN echo "=== [13/19] mesa + intel stuff + utils ===" && \
    pacman -S --noconfirm --needed \
        mesa \
        libva-mesa-driver \
        intel-media-driver \
        vulkan-intel \
        vulkan-icd-loader \
        libva-utils \
        mesa-utils \
        nvtop && \
    echo "=== [13/19] DONE ==="

# ---- 14-16: Keep your original steps 14-16 exactly the same ----

# ---- 17: Gaming packages (Steam + Sunshine) + Flatpak store ----
RUN echo "=== [17/19] Steam + Sunshine + gnome-software ===" && \
    pacman -S --noconfirm --needed \
        steam \
        sunshine \
        gnome-software && \
    echo "=== [17/19] DONE ==="

# ---- 18: Create user (keep yours) ----
RUN echo "=== [18/19] Create user ===" && \
    useradd -m -s /bin/bash -u 1000 cachyos && \
    echo "cachyos:cachyos" | chpasswd && \
    echo "cachyos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -aG audio,video,optical,storage cachyos && \
    echo "=== [18/19] DONE ==="

# ---- 19: Auto-start Steam + Sunshine on XFCE login ----
RUN echo "=== [19/19] Auto-start Steam + Sunshine ===" && \
    mkdir -p /home/cachyos/.config/autostart && \
    # Steam autostart
    cat > /home/cachyos/.config/autostart/steam.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=steam -silent
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Steam
EOF && \
    # Sunshine autostart (runs the host with tray)
    cat > /home/cachyos/.config/autostart/sunshine.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=sunshine
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Sunshine
EOF && \
    chown -R cachyos:cachyos /home/cachyos/.config && \
    echo "=== [19/19] DONE ==="

# Copy entrypoint
COPY start.sh /start.sh
RUN chmod +x /start.sh

VOLUME ["/home/cachyos", "/mnt/games"]
EXPOSE 5901 8080 47984-48000/udp  # Sunshine ports added
WORKDIR /home/cachyos
ENTRYPOINT ["/start.sh"]
