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

# Install XFCE core components individually (NOT as group)
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
    xorg-fonts-type1 \
    xorg-fonts-encodings \
    dbus \
    dbus-x11 && \
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

# VNC/Web
RUN pacman -S --noconfirm --needed \
    tigervnc \
    x11vnc \
    novnc \
    python-websockify \
    supervisor \
    nginx && \
    rm -rf /var/cache/pacman/pkg/*

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
    git \
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
