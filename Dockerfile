# ============================================================
# Diagnostic Dockerfile — CachyOS Headless
# ============================================================
# This file installs packages ONE AT A TIME with echo markers
# so you can see exactly which package fails in the build log.
#
# Run with:  docker build --progress=plain -t cachyos-test .
#
# When a step fails, search the log for "=== FAILED ===" to
# find the last successful package, then the next one is the
# one that broke.  Report back and we'll fix it.
# ============================================================

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

# ---- Init pacman & full system update ----
RUN echo "=== [1/18] Init pacman & update ===" && \
    pacman-key --init && \
    pacman-key --populate archlinux cachyos && \
    pacman -Sy --noconfirm archlinux-keyring cachyos-keyring && \
    pacman -Syu --noconfirm && \
    echo "=== [1/18] DONE ==="

# ---- 2: XFCE panel ----
RUN echo "=== [2/18] xfce4-panel ===" && \
    pacman -S --noconfirm --needed xfce4-panel && \
    echo "=== [2/18] DONE ==="

# ---- 3: XFCE session ----
RUN echo "=== [3/18] xfce4-session ===" && \
    pacman -S --noconfirm --needed xfce4-session && \
    echo "=== [3/18] DONE ==="

# ---- 4: XFCE window manager + desktop ----
RUN echo "=== [4/18] xfwm4 + xfdesktop ===" && \
    pacman -S --noconfirm --needed xfwm4 xfdesktop && \
    echo "=== [4/18] DONE ==="

# ---- 5: XFCE settings + appfinder + power manager ----
RUN echo "=== [5/18] xfce4-settings + xfce4-appfinder + xfce4-power-manager ===" && \
    pacman -S --noconfirm --needed xfce4-settings xfce4-appfinder xfce4-power-manager && \
    echo "=== [5/18] DONE ==="

# ---- 6: XFCE terminal ----
RUN echo "=== [6/18] xfce4-terminal ===" && \
    pacman -S --noconfirm --needed xfce4-terminal && \
    echo "=== [6/18] DONE ==="

# ---- 7: Thunar file manager + helpers ----
RUN echo "=== [7/18] thunar + thunar-volman + tumbler + gvfs ===" && \
    pacman -S --noconfirm --needed thunar thunar-volman tumbler gvfs && \
    echo "=== [7/18] DONE ==="

# ---- 8: Xorg server + tools ----
RUN echo "=== [8/18] xorg-server + xorg-xinit + xorg-xrandr + xorg-xauth + xorg-fonts-encodings ===" && \
    pacman -S --noconfirm --needed \
        xorg-server \
        xorg-xinit \
        xorg-xrandr \
        xorg-xauth \
        xorg-fonts-encodings && \
    echo "=== [8/18] DONE ==="

# ---- 9: D-Bus ----
RUN echo "=== [9/18] dbus ===" && \
    pacman -S --noconfirm --needed dbus && \
    echo "=== [9/18] DONE ==="

# ---- 10: Fonts ----
RUN echo "=== [10/18] ttf-dejavu + ttf-liberation + ttf-freefont + noto-fonts + noto-fonts-emoji ===" && \
    pacman -S --noconfirm --needed \
        ttf-dejavu \
        ttf-liberation \
        ttf-freefont \
        noto-fonts \
        noto-fonts-emoji && \
    echo "=== [10/18] DONE ==="

# ---- 11: Audio (PipeWire) ----
RUN echo "=== [11/18] pipewire + pipewire-pulse + pipewire-alsa + wireplumber + alsa-utils ===" && \
    pacman -S --noconfirm --needed \
        pipewire \
        pipewire-pulse \
        pipewire-alsa \
        wireplumber \
        alsa-utils && \
    echo "=== [11/18] DONE ==="

# ---- 12: VNC server ----
RUN echo "=== [12/18] tigervnc + supervisor ===" && \
    pacman -S --noconfirm --needed tigervnc supervisor && \
    echo "=== [12/18] DONE ==="  

# ---- 13: GPU / Graphics ----
RUN echo "=== [13/18] mesa + libva-mesa-driver + intel-media-driver + vulkan-intel + vulkan-tools ===" && \
    pacman -S --noconfirm --needed \
        mesa \
        libva-mesa-driver \
        intel-media-driver \
        vulkan-intel \
        vulkan-tools && \
    echo "=== [13/18] DONE ==="

# ---- 14: System utilities ----
RUN echo "=== [14/18] curl + wget + git + sudo + nano + vim ===" && \
    pacman -S --noconfirm --needed \
        curl \
        wget \
        git \
        sudo \
        nano \
        vim && \
    echo "=== [14/18] DONE ==="

# ---- 15: Firefox ----
RUN echo "=== [15/18] firefox ===" && \
    pacman -S --noconfirm --needed firefox && \
    echo "=== [15/18] DONE ==="

# ---- 16: Extras (fuse3, flatpak, certs, openssl) ----
RUN echo "=== [16/18] fuse3 + flatpak + ca-certificates-utils + openssl ===" && \
    pacman -S --noconfirm --needed \
        fuse3 \
        flatpak \
        ca-certificates-utils \
        openssl && \
    echo "=== [16/18] DONE ==="

# ---- 17: Python + noVNC + websockify ----
RUN echo "=== [17/18] python + python-pip + websockify (venv) + noVNC (v1.5.0) ===" && \
    pacman -S --noconfirm --needed python python-pip && \
    rm -rf /var/cache/pacman/pkg/* && \
    python -m venv /opt/noVNC-env && \
    /opt/noVNC-env/bin/pip install --no-cache-dir websockify && \
    git clone --depth 1 --branch v1.5.0 \
        https://github.com/novnc/noVNC.git /usr/share/novnc && \
    rm -rf /usr/share/novnc/.git && \
    echo "=== [17/18] DONE ==="

# ---- 18: User + VNC config + entrypoint ----
RUN echo "=== [18/18] Create user, copy configs ===" && \
    useradd -m -s /bin/bash -u 1000 cachyos && \
    echo "cachyos:cachyos" | chpasswd && \
    echo "cachyos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -aG audio,video,optical,storage cachyos && \
    mkdir -p /home/cachyos/.vnc && \
    chown -R cachyos:cachyos /home/cachyos/.vnc && \
    printf '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4\n' \
        > /home/cachyos/.vnc/xstartup && \
    chmod +x /home/cachyos/.vnc/xstartup && \
    chown cachyos:cachyos /home/cachyos/.vnc/xstartup && \
    mkdir -p /var/log/supervisor /etc/supervisor/conf.d && \
    echo "=== [18/18] DONE ==="

# Copy runtime configs
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh
COPY vnc-start.sh /usr/local/bin/vnc-start.sh
COPY xfce-start.sh /usr/local/bin/xfce-start.sh
COPY pipewire-start.sh /usr/local/bin/pipewire-start.sh
RUN chmod +x /start.sh /usr/local/bin/vnc-start.sh /usr/local/bin/xfce-start.sh /usr/local/bin/pipewire-start.sh

VOLUME ["/home/cachyos", "/mnt/games"]
EXPOSE 5901 8080
WORKDIR /home/cachyos
ENTRYPOINT ["/start.sh"]
