FROM cachyos/cachyos-v3:latest

LABEL maintainer="adam2893"
LABEL description="CachyOS Headless - Headless CachyOS desktop with Steam, Sunshine, and GPU acceleration"

ENV \
    USER=cachyos \
    PASSWD=cachyos \
    HOME=/home/cachyos \
    PUID=1000 \
    PGID=1000 \
    DISPLAY=:1 \
    RESOLUTION=1920x1080 \
    DEPTH=24 \
    TERM=xterm \
    PORT_VNC=5901 \
    PORT_NOVNC_WEB=8080 \
    ENABLE_STEAM=true \
    ENABLE_SUNSHINE=true \
    FORCE_X11_DUMMY_CONFIG=true \
    XORG_SOCKET_DIR="/tmp/.X11-unix" \
    XDG_RUNTIME_DIR="/tmp/.X11-unix/run" \
    XDG_SESSION_TYPE="x11" \
    XDG_DATA_DIRS="/home/cachyos/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share/:/usr/share/"

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

# ---- 2: Xorg server + x11vnc + xorg apps ----
RUN echo "=== [2/20] Xorg + x11vnc + xorg apps ===" && \
    pacman -S --noconfirm --needed \
        xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xsetroot \
        xorg-xhost xorg-xinput xorg-xkill xorg-xprop xorg-xwininfo \
        xorg-xauth xorg-apps xorg-fonts-misc \
        xf86-input-evdev xterm \
        x11vnc \
        xf86-video-dummy && \
    echo "=== [2/20] DONE ==="

# ---- 3: Supervisor ----
RUN echo "=== [3/20] Supervisor ===" && \
    pacman -S --noconfirm --needed supervisor && \
    mkdir -p /var/log/supervisor /etc/supervisor.d && \
    echo "=== [3/20] DONE ==="

# ---- 4: D-Bus ----
RUN echo "=== [4/20] dbus ===" && \
    pacman -S --noconfirm --needed dbus dbus-glib && \
    echo "=== [4/20] DONE ==="

# ---- 5-7: XFCE desktop (split for cache) ----
RUN echo "=== [5/20] xfce4-panel ===" && pacman -S --noconfirm --needed xfce4-panel && echo "=== [5/20] DONE ==="
RUN echo "=== [6/20] xfce4-session + xfwm4 + xfdesktop ===" && \
    pacman -S --noconfirm --needed xfce4-session xfwm4 xfdesktop && echo "=== [6/20] DONE ==="
RUN echo "=== [7/20] xfce4-settings + appfinder + power-manager + terminal + thunar ===" && \
    pacman -S --noconfirm --needed \
        xfce4-settings xfce4-appfinder xfce4-power-manager \
        xfce4-terminal thunar thunar-volman tumbler gvfs && \
    echo "=== [7/20] DONE ==="

# ---- 8: Fonts ----
RUN echo "=== [8/20] fonts ===" && \
    pacman -S --noconfirm --needed noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation && \
    echo "=== [8/20] DONE ==="

# ---- 9: PipeWire audio ----
RUN echo "=== [9/20] pipewire + alsa + pulse + wireplumber ===" && \
    pacman -S --noconfirm --needed pipewire pipewire-alsa pipewire-pulse wireplumber alsa-utils && \
    echo "=== [9/20] DONE ==="

# ---- 10: noVNC (Python venv + websockify + web files) ----
RUN echo "=== [10/20] noVNC ===" && \
    pacman -S --noconfirm --needed python python-pip curl && \
    mkdir -p /opt/noVNC-env && \
    python -m venv /opt/noVNC-env && \
    /opt/noVNC-env/bin/pip install --no-cache-dir websockify && \
    mkdir -p /usr/share/novnc && \
    curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz | \
    tar -xz --strip-components=1 -C /usr/share/novnc && \
    echo "=== [10/20] DONE ==="

# ---- 11: GPU extras (libva + intel-media + vulkan) ----
RUN echo "=== [11/20] GPU extras ===" && \
    pacman -S --noconfirm --needed libva-mesa-driver intel-media-driver vulkan-icd-loader libva-utils mesa-utils nvtop && \
    echo "=== [11/20] DONE ==="

# ---- 12: General tools ----
RUN echo "=== [12/20] tools ===" && \
    pacman -S --noconfirm --needed curl wget git sudo nano vim htop jq wmctrl xdotool && \
    echo "=== [12/20] DONE ==="

# ---- 13: Firefox ----
RUN echo "=== [13/20] firefox ===" && \
    pacman -S --noconfirm --needed firefox && \
    echo "=== [13/20] DONE ==="

# ---- 14: Flatpak ----
RUN echo "=== [14/20] flatpak ===" && \
    pacman -S --noconfirm --needed fuse3 flatpak ca-certificates-utils openssl xdg-desktop-portal-gtk && \
    echo "=== [14/20] DONE ==="

# ---- 15: Steam ----
RUN echo "=== [15/20] Steam ===" && \
    pacman -S --noconfirm --needed libvpl sdl2-compat zimg l-smash libglvnd && \
    pacman -S --noconfirm --needed steam && \
    echo "=== [15/20] DONE ==="

# ---- 15b: 32-bit + Gamemode for optimal Steam + Arc B580 performance ----
RUN echo "=== [15b/20] 32-bit + Gamemode ===" && \
    pacman -S --noconfirm --needed \
        lib32-mesa-git lib32-vulkan-icd-loader lib32-libva lib32-gamemode \
        gamemode && \
    echo "=== [15b/20] DONE ==="

# ---- 16: Create user + sudo (moved up — needed for yay) ----
RUN echo "=== [16/20] User setup ===" && \
    groupadd -g 1000 cachyos && \
    useradd -m -u 1000 -g cachyos -G audio,video,wheel -s /bin/bash cachyos && \
    echo "cachyos:${PASSWD}" | chpasswd && \
    echo "cachyos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/cachyos && \
    mkdir -p /home/cachyos/.config/autostart /home/cachyos/.config/sunshine /home/cachyos/.cache/log && \
    chown -R cachyos:cachyos /home/cachyos && \
    echo "=== [16/20] DONE ==="

# ---- 16b: Install yay (AUR helper, needs user) ----
RUN echo "=== [16b/20] Install yay ===" && \
    pacman -S --noconfirm --needed base-devel git && \
    su - cachyos -c "git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg --noconfirm --syncdeps --install" && \
    rm -rf /tmp/yay /home/cachyos/.cache/yay && \
    echo "=== [16b/20] DONE ==="

# ---- 16c: Sunshine (from AUR via yay, like Josh5) ----
RUN echo "=== [16c/20] Sunshine ===" && \
    su - cachyos -c "yay -Syu --noconfirm --needed miniupnpc sunshine-bin" && \
    setcap cap_sys_admin+p "$(readlink -f $(which sunshine))" && \
    echo "=== [16c/20] DONE ==="

# ---- 18: Flatpak system-level setup ----
RUN echo "=== [18/20] Flatpak system-level setup ===" && \
    chmod u-s /usr/bin/bwrap 2>/dev/null || true && \
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && \
    su - cachyos -c "flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo" && \
    echo "=== [18/20] DONE ==="

# ---- 19: Final cleanup ----
RUN echo "=== [19/20] Cleanup ===" && \
    pacman -Sc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/* /var/lib/pacman/sync/* /home/cachyos/.cache/yay /tmp/* && \
    echo "=== [19/20] DONE ==="

# ---- 20: Add overlay files ----
COPY supervisord.conf /etc/supervisord.conf
COPY etc/supervisor.d/*.ini /etc/supervisor.d/
COPY etc/cont-init.d/*.sh /etc/cont-init.d/
COPY usr/bin/* /usr/bin/
COPY templates/ /templates/

RUN chmod +x /etc/cont-init.d/*.sh /usr/bin/start-*.sh /usr/bin/common-functions.sh /usr/bin/xfce4-minimise-all-windows /usr/bin/start-wireplumber.sh /usr/bin/start-pipewire-pulse.sh

COPY start.sh /start.sh
RUN chmod +x /start.sh

VOLUME ["/home/cachyos", "/mnt/games"]
EXPOSE 5901 8080 47984-48000/udp
WORKDIR /home/cachyos
ENTRYPOINT ["/start.sh"]
