FROM cachyos/cachyos-v3:latest

ENV USER=cachyos \
    PASSWD=cachyos \
    HOME=/home/cachyos \
    DISPLAY=:1 \
    TERM=xterm \
    PUID=1000 \
    PGID=1000

# Fix: Update keyring first and choose PipeWire over PulseAudio (modern standard)
RUN pacman-key --init && \
    pacman-key --populate archlinux cachyos && \
    pacman -Sy --noconfirm archlinux-keyring cachyos-keyring && \
    pacman -Syu --noconfirm

# Install packages in smaller groups to isolate errors
RUN pacman -S --noconfirm --needed \
    xfce4 xfce4-terminal xfce4-goodies \
    xorg-server xorg-xinit xorg-xrandr xorg-xauth xorg-fonts-misc \
    dbus-x11 ttf-dejavu ttf-liberation noto-fonts && \
    rm -rf /var/cache/pacman/pkg/*

# Audio: Use PipeWire (not PulseAudio+PipeWire combo which conflicts)
RUN pacman -S --noconfirm --needed \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    alsa-utils && \
    rm -rf /var/cache/pacman/pkg/*

# VNC and web interface
RUN pacman -S --noconfirm --needed \
    tigervnc x11vnc novnc websockify \
    supervisor nginx && \
    rm -rf /var/cache/pacman/pkg/*

# GPU support (Intel Arc)
RUN pacman -S --noconfirm --needed \
    mesa libva-mesa-driver intel-media-driver \
    vulkan-intel vulkan-tools && \
    rm -rf /var/cache/pacman/pkg/*

# System utilities
RUN pacman -S --noconfirm --needed \
    curl wget git sudo nano vim \
    firefox fuse3 flatpak ca-certificates openssl && \
    rm -rf /var/cache/pacman/pkg/*

# Create user
RUN useradd -m -s /bin/bash -u 1000 cachyos && \
    echo "cachyos:cachyos" | chpasswd && \
    echo "cachyos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -aG audio,video,optical,storage cachyos

# Setup VNC
RUN mkdir -p /home/cachyos/.vnc && \
    echo "cachyos" | vncpasswd -f > /home/cachyos/.vnc/passwd && \
    chmod 600 /home/cachyos/.vnc/passwd && \
    chown -R cachyos:cachyos /home/cachyos/.vnc && \
    echo -e '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4' > /home/cachyos/.vnc/xstartup && \
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
