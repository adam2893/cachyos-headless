FROM cachyos/cachyos-v3:latest

ENV USER=cachyos \
    PASSWD=cachyos \
    HOME=/home/cachyos \
    DISPLAY=:1 \
    TERM=xterm \
    PUID=1000 \
    PGID=1000 \
    LIBVA_DRIVER_NAME=iHD \
    VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json

# Install packages in one layer to keep image size down
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
    xfce4 xfce4-terminal xfce4-goodies \
    tigervnc x11vnc novnc websockify \
    pulseaudio pulseaudio-alsa alsa-utils \
    pipewire pipewire-pulse wireplumber \
    mesa intel-compute-runtime intel-gmmlib \
    intel-graphics-compiler libva-mesa-driver \
    intel-media-driver vulkan-intel vulkan-tools \
    supervisor nginx curl wget git sudo nano \
    xorg-server xorg-xinit xorg-xrandr xorg-xauth \
    dbus-x11 ttf-dejavu ttf-liberation noto-fonts \
    firefox fuse3 flatpak ca-certificates openssl && \
    rm -rf /var/cache/pacman/pkg/* /tmp/* /var/tmp/*

# Create user
RUN useradd -m -s /bin/bash -u 1000 cachyos && \
    echo "cachyos:cachyos" | chpasswd && \
    echo "cachyos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -aG audio,video,optical,storage cachyos && \
    mkdir -p /home/cachyos/.vnc && \
    echo "cachyos" | vncpasswd -f > /home/cachyos/.vnc/passwd && \
    chmod 600 /home/cachyos/.vnc/passwd && \
    chown -R cachyos:cachyos /home/cachyos/.vnc

# Setup XFCE startup
RUN echo -e '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4' > /home/cachyos/.vnc/xstartup && \
    chmod +x /home/cachyos/.vnc/xstartup && \
    chown cachyos:cachyos /home/cachyos/.vnc/xstartup

# Setup directories
RUN mkdir -p /usr/share/novnc /var/log/supervisor /etc/supervisor/conf.d

# Copy config files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh && chmod 666 /etc/supervisor/conf.d/supervisord.conf

VOLUME ["/home/cachyos", "/mnt/games", "/dev/shm"]
EXPOSE 5901 8080
WORKDIR /home/cachyos
ENTRYPOINT ["/start.sh"]
