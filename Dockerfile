FROM cachyos/cachyos-v3:latest

ENV USER=cachyos \
    PASSWD=cachyos \
    HOME=/home/cachyos \
    DISPLAY=:1 \
    TERM=xterm \
    PUID=1000 \
    PGID=1000

# Initialize pacman and update system
RUN pacman-key --init && \
    pacman-key --populate archlinux cachyos && \
    pacman -Sy --noconfirm archlinux-keyring cachyos-keyring && \
    pacman -Syu --noconfirm

# Install XFCE and Xorg
RUN pacman -S --noconfirm --needed \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    xfwm4 \
    xfdesktop \
    xfce4-appfinder \
    xfce4-power-manager \
    thunar \
    thunar-volman \
    tumbler \
    gvfs \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xorg-xauth \
    xorg-fonts-encodings \
    dbus && \
    rm -rf /var/cache/pacman/pkg/*

# Install fonts
RUN pacman -S --noconfirm --needed \
    ttf-dejavu \
    ttf-liberation \
    ttf-freefont \
    noto-fonts \
    noto-fonts-emoji && \
    rm -rf /var/cache/pacman/pkg/*

# Audio (PipeWire)
RUN pacman -S --noconfirm --needed \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    alsa-utils && \
    rm -rf /var/cache/pacman/pkg/*

# VNC/Web - Removed novnc and python-websockify (not in repos)
RUN pacman -S --noconfirm --needed \
    tigervnc \
    x11vnc \
    supervisor \
    nginx \
    python \
    python-pip \
    git && \
    rm -rf /var/cache/pacman/pkg/*

# Install noVNC and websockify via pip (not in pacman repos)
RUN pip3 install --break-system-packages websockify && \
    mkdir -p /usr/share/novnc && \
    git clone --depth 1 https://github.com/novnc/noVNC.git /usr/share/novnc && \
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html && \
    rm -rf /usr/share/novnc/.git

# GPU/Graphics
RUN pacman -S --noconfirm --needed \
    mesa \
    libva-mesa-driver \
    intel-media-driver \
    vulkan-intel \
    vulkan-tools && \
    rm -rf /var/cache/pacman/pkg/*

# Utilities
RUN pacman -S --noconfirm --needed \
    curl \
    wget \
    sudo \
    nano \
    vim \
    firefox \
    fuse3 \
    flatpak \
    ca-certificates-utils \
    openssl && \
    rm -rf /var/cache/pacman/pkg/*

# Create user
RUN useradd -m -s /bin/bash -u 1000 cachyos && \
    echo "cachyos:cachyos" | chpasswd && \
    echo "cachyos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -aG audio,video,optical,storage cachyos && \
    mkdir -p /home/cachyos/.vnc && \
    echo "cachyos" | vncpasswd -f > /home/cachyos/.vnc/passwd && \
    chmod 600 /home/cachyos/.vnc/passwd && \
    chown -R cachyos:cachyos /home/cachyos/.vnc && \
    printf '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4\n' > /home/cachyos/.vnc/xstartup && \
    chmod +x /home/cachyos/.vnc/xstartup && \
    chown cachyos:cachyos /home/cachyos/.vnc/xstartup

# Setup directories
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d

# Copy config files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

VOLUME ["/home/cachyos", "/mnt/games", "/dev/shm"]
EXPOSE 5901 8080
WORKDIR /home/cachyos
ENTRYPOINT ["/start.sh"]
