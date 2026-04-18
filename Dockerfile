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

# ---- 1: Init pacman & full system update + multilib ----
RUN echo "=== [1/20] Init pacman & update + multilib ===" && \
    pacman-key --init && \
    pacman-key --populate archlinux cachyos && \
    pacman -Sy --noconfirm archlinux-keyring cachyos-keyring && \
    (grep -q '^\[multilib\]' /etc/pacman.conf || echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf) && \
    pacman -Syu --noconfirm && \
    echo "=== [1/20] DONE ==="

# ---- 1b: FORCE bleeding-edge mesa-git FIRST (Arc B580) ----
RUN echo "=== [1b/20] Bleeding-edge mesa-git for Arc B580 ===" && \
    pacman -S --noconfirm --needed mesa-git lib32-mesa-git && \
    echo "=== [1b/20] DONE ==="

# ---- 2-16: XFCE + audio + fonts + dbus + tigervnc + GPU extras + tools + firefox + flatpak (unchanged) ----
RUN echo "=== [2/20] xfce4-panel ===" && pacman -S --noconfirm --needed xfce4-panel && echo "=== [2/20] DONE ==="
RUN echo "=== [3/20] xfce4-session ===" && pacman -S --noconfirm --needed xfce4-session && echo "=== [3/20] DONE ==="
RUN echo "=== [4/20] xfwm4 + xfdesktop ===" && pacman -S --noconfirm --needed xfwm4 xfdesktop && echo "=== [4/20] DONE ==="
RUN echo "=== [5/20] xfce4-settings + xfce4-appfinder + xfce4-power-manager ===" && pacman -S --noconfirm --needed xfce4-settings xfce4-appfinder xfce4-power-manager && echo "=== [5/20] DONE ==="
RUN echo "=== [6/20] xfce4-terminal ===" && pacman -S --noconfirm --needed xfce4-terminal && echo "=== [6/20] DONE ==="
RUN echo "=== [7/20] thunar + volman + tumbler + gvfs ===" && pacman -S --noconfirm --needed thunar thunar-volman tumbler gvfs && echo "=== [7/20] DONE ==="
RUN echo "=== [8/20] xorg-server + xorg-xinit + xorg-xrandr + xorg-xset + xorg-xsetroot ===" && pacman -S --noconfirm --needed xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xsetroot && echo "=== [8/20] DONE ==="
RUN echo "=== [9/20] dbus + dbus-glib ===" && pacman -S --noconfirm --needed dbus dbus-glib && echo "=== [9/20] DONE ==="
RUN echo "=== [10/20] fonts + noto + ttf-dejavu + ttf-liberation ===" && pacman -S --noconfirm --needed noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation && echo "=== [10/20] DONE ==="
RUN echo "=== [11/20] pipewire + alsa + pulse + wireplumber ===" && pacman -S --noconfirm --needed pipewire pipewire-alsa pipewire-pulse wireplumber alsa-utils && echo "=== [11/20] DONE ==="
RUN echo "=== [12/20] tigervnc ===" && pacman -S --noconfirm --needed tigervnc && echo "=== [12/20] DONE ==="
# ---- noVNC Python venv (websockify) ----
RUN echo "=== [noVNC] Setting up Python venv for websockify ===" && \
    pacman -S --noconfirm --needed python python-pip && \
    mkdir -p /opt/noVNC-env && \
    python -m venv /opt/noVNC-env && \
    /opt/noVNC-env/bin/pip install --no-cache-dir websockify && \
    echo "=== [noVNC] DONE ==="
RUN echo "=== [noVNC web files] Downloading and installing ===" && \
    pacman -S --noconfirm --needed curl && \
    mkdir -p /usr/share/novnc && \
    curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz | \
    tar -xz --strip-components=1 -C /usr/share/novnc && \
    echo "=== [noVNC web files] DONE ==="
RUN echo "=== [13/20] GPU extras (libva + intel-media + vulkan) ===" && pacman -S --noconfirm --needed libva-mesa-driver intel-media-driver vulkan-icd-loader libva-utils mesa-utils nvtop && echo "=== [13/20] DONE ==="
RUN echo "=== [14/20] curl + wget + git + sudo + nano + vim ===" && pacman -S --noconfirm --needed curl wget git sudo nano vim && echo "=== [14/20] DONE ==="
RUN echo "=== [15/20] firefox ===" && pacman -S --noconfirm --needed firefox && echo "=== [15/20] DONE ==="
RUN echo "=== [16/20] fuse3 + flatpak + ca-certificates + openssl ===" && pacman -S --noconfirm --needed fuse3 flatpak ca-certificates-utils openssl && echo "=== [16/20] DONE ==="

# ---- 17: Steam + gnome-software (now safe because mesa-git is already installed) ----
RUN echo "=== [17/20] Steam + gnome-software ===" && \
    pacman -S --noconfirm --needed libvpl sdl2-compat zimg l-smash libglvnd && \
    pacman -S --noconfirm --needed steam gnome-software && \
    echo "=== [17/20] DONE ==="

# ---- 17b: 32-bit + Gamemode for optimal Steam + Arc B580 performance ----
RUN echo "=== [17b/20] 32-bit + Gamemode ===" && \
    pacman -S --noconfirm --needed \
        lib32-mesa-git lib32-vulkan-icd-loader lib32-libva lib32-gamemode \
        gamemode && \
    echo "=== [17b/20] DONE ==="

# ---- 18: Create user + sudo + groups + autostart Steam + Sunshine ----
RUN echo "=== [18/20] User setup + autostart ===" && \
    groupadd -g 1000 cachyos && \
    useradd -m -u 1000 -g cachyos -G audio,video,wheel -s /bin/bash cachyos && \
    echo "cachyos:${PASSWD}" | chpasswd && \
    echo "cachyos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cachyos && \
    mkdir -p /home/cachyos/.config/autostart && \
    # Steam autostart (silent)
    echo '[Desktop Entry]' > /home/cachyos/.config/autostart/steam.desktop && \
    echo 'Type=Application' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'Exec=env MESA_LOADER_DRIVER_OVERRIDE=iris __GLX_VENDOR_LIBRARY_NAME=mesa LIBGL_ALWAYS_SOFTWARE=1 gamemoderun steam -bigpicture -silent -no-cef-sandbox' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'Hidden=false' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'NoDisplay=false' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'X-GNOME-Autostart-enabled=true' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'Name=Steam' >> /home/cachyos/.config/autostart/steam.desktop && \
    # Sunshine autostart (user-level flatpak, correct command + additional-install)
    echo '[Desktop Entry]' > /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'Type=Application' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'Exec=flatpak run --user dev.lizardbyte.app.Sunshine' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'Hidden=false' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'NoDisplay=false' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'X-GNOME-Autostart-enabled=true' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'Name=Sunshine' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    chown -R cachyos:cachyos /home/cachyos && \
    echo "=== [18/20] DONE ==="
    
RUN echo "=== [Flatpak user-level setup] ===" && \
    rm -rf /home/cachyos/.local/share/flatpak/* /home/cachyos/.cache/flatpak/* 2>/dev/null || true && \
    su - cachyos -c "flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" && \
    su - cachyos -c "flatpak --user update --appstream" && \
    echo "=== [Flatpak user-level setup] DONE ==="

# ---- 19: Final cleanup + start script ----
RUN echo "=== [19/20] Cleanup ===" && \
    pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /tmp/* && \
    echo "=== [19/20] DONE ==="

COPY start.sh /start.sh
RUN chmod +x /start.sh

VOLUME ["/home/cachyos", "/mnt/games"]
EXPOSE 5901 8080 47984-48000/udp
WORKDIR /home/cachyos
ENTRYPOINT ["/start.sh"]
