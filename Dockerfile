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

# ---- 1: Init pacman & full system update + multilib for Steam ----
RUN echo "=== [1/19] Init pacman & update + multilib ===" && \
    pacman-key --init && \
    pacman-key --populate archlinux cachyos && \
    pacman -Sy --noconfirm archlinux-keyring cachyos-keyring && \
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    pacman -Syu --noconfirm && \
    echo "=== [1/19] DONE ==="

# ---- 2-11: XFCE + audio + fonts + dbus (your original steps) ----
RUN echo "=== [2/19] xfce4-panel ===" && pacman -S --noconfirm --needed xfce4-panel && echo "=== [2/19] DONE ==="
RUN echo "=== [3/19] xfce4-session ===" && pacman -S --noconfirm --needed xfce4-session && echo "=== [3/19] DONE ==="
RUN echo "=== [4/19] xfwm4 + xfdesktop ===" && pacman -S --noconfirm --needed xfwm4 xfdesktop && echo "=== [4/19] DONE ==="
RUN echo "=== [5/19] xfce4-settings + xfce4-appfinder + xfce4-power-manager ===" && pacman -S --noconfirm --needed xfce4-settings xfce4-appfinder xfce4-power-manager && echo "=== [5/19] DONE ==="
RUN echo "=== [6/19] xfce4-terminal ===" && pacman -S --noconfirm --needed xfce4-terminal && echo "=== [6/19] DONE ==="
RUN echo "=== [7/19] thunar + thunar-volman + tumbler + gvfs ===" && pacman -S --noconfirm --needed thunar thunar-volman tumbler gvfs && echo "=== [7/19] DONE ==="
RUN echo "=== [8/19] xorg-server + tools ===" && pacman -S --noconfirm --needed xorg-server xorg-xinit xorg-xrandr xorg-xauth xorg-fonts-encodings && echo "=== [8/19] DONE ==="
RUN echo "=== [9/19] dbus ===" && pacman -S --noconfirm --needed dbus && echo "=== [9/19] DONE ==="
RUN echo "=== [10/19] fonts ===" && pacman -S --noconfirm --needed ttf-dejavu ttf-liberation ttf-freefont noto-fonts noto-fonts-emoji && echo "=== [10/19] DONE ==="
RUN echo "=== [11/19] pipewire audio ===" && pacman -S --noconfirm --needed pipewire pipewire-pulse pipewire-alsa wireplumber alsa-utils && echo "=== [11/19] DONE ==="

# ---- 12: VNC server (tigervnc) ----
RUN echo "=== [12/19] tigervnc ===" && pacman -S --noconfirm --needed tigervnc && echo "=== [12/19] DONE ==="

# ---- 13: GPU (bleeding-edge mesa-git already in base + Arc extras) ----
RUN echo "=== [13/19] GPU extras for Arc B580 ===" && \
    pacman -S --noconfirm --needed \
        libva-mesa-driver \
        intel-media-driver \
        vulkan-icd-loader \
        libva-utils \
        mesa-utils \
        nvtop && \
    echo "=== [13/19] DONE ==="

# ---- 14: System utilities ----
RUN echo "=== [14/19] curl + wget + git + sudo + nano + vim ===" && \
    pacman -S --noconfirm --needed curl wget git sudo nano vim && \
    echo "=== [14/19] DONE ==="

# ---- 15: Firefox ----
RUN echo "=== [15/19] firefox ===" && pacman -S --noconfirm --needed firefox && echo "=== [15/19] DONE ==="

# ---- 16: Extras (fuse3, flatpak, certs, openssl) ----
RUN echo "=== [16/19] fuse3 + flatpak + ca-certificates-utils + openssl ===" && \
    pacman -S --noconfirm --needed fuse3 flatpak ca-certificates-utils openssl && \
    echo "=== [16/19] DONE ==="

# ---- 17: Steam + gnome-software (bleeding edge Arc B580) ----
RUN echo "=== [17/19] Steam + gnome-software (bleeding edge) ===" && \
    # Aggressive removal of EVERY stable mesa package that conflicts
    pacman -Rdd --noconfirm mesa lib32-mesa mesa-libgl lib32-mesa-libgl \
        vulkan-mesa-implicit-layers libva-mesa-driver 2>/dev/null || true && \
    # Full upgrade but BLOCK stable mesa from coming back
    pacman -Syu --noconfirm --ignore mesa,lib32-mesa && \
    # Force the bleeding-edge git versions for maximum Arc B580 perf
    pacman -S --noconfirm --needed mesa-git lib32-mesa-git && \
    # Pre-install the exact providers that were prompting earlier
    pacman -S --noconfirm --needed libvpl sdl2-compat zimg l-smash libglvnd && \
    # Now Steam installs cleanly on top of git mesa
    pacman -S --noconfirm --needed steam gnome-software && \
    echo "=== [17/19] DONE ==="
    
# ---- 18: Create user ----
RUN echo "=== [18/19] Create user ===" && \
    useradd -m -s /bin/bash -u 1000 cachyos && \
    echo "cachyos:cachyos" | chpasswd && \
    echo "cachyos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -aG audio,video,optical,storage cachyos && \
    echo "=== [18/19] DONE ==="

# ---- 19: Auto-start Steam + Sunshine ----
RUN echo "=== [19/19] Auto-start Steam + Sunshine ===" && \
    mkdir -p /home/cachyos/.config/autostart && \
    echo '[Desktop Entry]' > /home/cachyos/.config/autostart/steam.desktop && \
    echo 'Type=Application' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'Exec=steam -silent' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'Hidden=false' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'NoDisplay=false' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'X-GNOME-Autostart-enabled=true' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo 'Name=Steam' >> /home/cachyos/.config/autostart/steam.desktop && \
    echo '[Desktop Entry]' > /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'Type=Application' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'Exec=sunshine' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'Hidden=false' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'NoDisplay=false' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'X-GNOME-Autostart-enabled=true' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    echo 'Name=Sunshine' >> /home/cachyos/.config/autostart/sunshine.desktop && \
    chown -R cachyos:cachyos /home/cachyos/.config && \
    echo "=== [19/19] DONE ==="

# Copy entrypoint
COPY start.sh /start.sh
RUN chmod +x /start.sh

VOLUME ["/home/cachyos", "/mnt/games"]
EXPOSE 5901 8080 47984-48000/udp
WORKDIR /home/cachyos
ENTRYPOINT ["/start.sh"]
