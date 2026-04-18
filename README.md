<p align="center">
  <img src="https://cachyos.org/_astro/logo.DuMERIP6_qzDwT.svg" alt="CachyOS" width="120"/>
</p>

<h1 align="center">CachyOS Headless</h1>

<p align="center">
  <strong>A headless CachyOS gaming desktop in Docker — GPU-accelerated Xorg + Sunshine + VNC</strong><br/>
  <sub>Built for Unraid · Intel Arc GPU ready · Inspired by
    <a href="https://github.com/Steam-Headless/docker-steam-headless">Steam-Headless</a>
  </sub>
</p>

<p align="center">
  <a href="https://ghcr.io"><img src="https://img.shields.io/badge/registry-ghcr.io-blue?logo=github" alt="GHCR"/></a>
  <a href="https://hub.docker.com/r/cachyos/cachyos-v3"><img src="https://img.shields.io/badge/base-cachyos%2Fcachyos--v3-orange?logo=linux" alt="Base Image"/></a>
  <a href="https://cachyos.org"><img src="https://img.shields.io/badge/distro-CachyOS-blue?logo=arch-linux" alt="CachyOS"/></a>
  <a href="https://xfce.org"><img src="https://img.shields.io/badge/desktop-XFCE4-blue?logo=xfce" alt="XFCE4"/></a>
  <a href="https://x.org"><img src="https://img.shields.io/badge/X-Xorg-green?logo=x.org" alt="Xorg"/></a>
  <a href="https://github.com/novnc/noVNC"><img src="https://img.shields.io/badge/web%20client-noVNC-9cf?logo=firefox-browser" alt="noVNC"/></a>
  <a href="https://pipewire.org"><img src="https://img.shields.io/badge/audio-PipeWire-purple?logo=linux" alt="PipeWire"/></a>
  <a href="https://github.com/LizardByte/Sunshine"><img src="https://img.shields.io/badge/streaming-Sunshine-yellow?logo=sunshine" alt="Sunshine"/></a>
  <br/><br/>
  <img src="https://img.shields.io/badge/arch-linux%2Famd64-x86__64__v3-informational" alt="x86-64-v3"/>
  <img src="https://img.shields.io/badge/gpu-intel%20arc-green?logo=intel" alt="Intel Arc"/>
</p>

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🐧 **CachyOS Base** | Built on `cachyos/cachyos-v3` — Arch-based with BORE scheduler & x86-64-v3 optimisations |
| 🖥️ **GPU-Accelerated Xorg** | Real X server with hardware GLX/Vulkan — not a virtual framebuffer |
| 🎮 **Steam + Sunshine** | Native Steam with Sunshine game streaming (Moonlight compatible) |
| 🔗 **Triple Access** | Sunshine stream, native VNC (port `5901`), and browser-based noVNC (port `8080`) |
| 🎮 **Intel GPU Support** | Mesa-git, VA-API (`iHD`), Vulkan — optimised for Intel Arc B580 |
| 🔊 **PipeWire Audio** | Modern audio stack with PulseAudio compatibility (`pipewire-pulse`) |
| 🔄 **Auto-Restart** | All services managed via `supervisord` with automatic recovery |
| 📦 **Flatpak Ready** | Install additional apps (Spotify, Discord, etc.) at runtime |
| 🏗️ **cont-init.d Pattern** | Modular runtime configuration scripts (like Steam-Headless) |
| 💾 **Persistent Storage** | Home directory and game storage survive container restarts |

---

## 🚀 Quick Start

### Pull

```bash
docker pull ghcr.io/adam2893/cachyos-headless:latest
```

### Docker Compose

```yaml
services:
  cachyos-headless:
    image: ghcr.io/adam2893/cachyos-headless:latest
    container_name: CachyOS-Headless
    privileged: true
    shm_size: '2gb'
    ports:
      - "5901:5901"         # VNC
      - "8080:8080"         # noVNC (browser)
      - "47984-48000:47984-48000/udp"  # Sunshine
    volumes:
      - /mnt/user/appdata/cachyos:/home/cachyos   # persistent home
      - /mnt/user/games:/mnt/games                 # game storage
    devices:
      - /dev/dri:/dev/dri                          # Intel GPU passthrough
    environment:
      - USER=cachyos
      - PASSWD=cachyos
      - ENABLE_STEAM=true
      - ENABLE_SUNSHINE=true
    restart: unless-stopped
```

### Docker CLI

```bash
docker run -d \
  --name CachyOS-Headless \
  --privileged \
  --shm-size=2gb \
  -p 5901:5901 -p 8080:8080 \
  -p 47984-48000:47984-48000/udp \
  -v /mnt/user/appdata/cachyos:/home/cachyos \
  -v /mnt/user/games:/mnt/games \
  -e USER=cachyos -e PASSWD=cachyos \
  -e ENABLE_STEAM=true -e ENABLE_SUNSHINE=true \
  ghcr.io/adam2893/cachyos-headless:latest
```

### Connect

| Method | Address | Notes |
|--------|---------|-------|
| 🌟 **Sunshine/Moonlight** | `<your-ip>:47989` | Best quality — hardware-encoded stream |
| 🖥️ **VNC Client** | `<your-ip>:5901` | Direct VNC connection |
| 🌐 **Browser** (noVNC) | `http://<your-ip>:8080/vnc.html` | No client needed |

---

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|:-------:|-------------|
| `USER` | `cachyos` | Desktop username |
| `PASSWD` | `cachyos` | User password |
| `DISPLAY` | `:1` | X11 display number |
| `RESOLUTION` | `1920x1080` | Desktop resolution (used by dummy xorg.conf) |
| `DEPTH` | `24` | Colour depth |
| `PUID` | `1000` | User UID |
| `PGID` | `1000` | User GID |
| `PORT_VNC` | `5901` | VNC port |
| `PORT_NOVNC_WEB` | `8080` | noVNC web port |
| `ENABLE_STEAM` | `true` | Auto-start Steam in Big Picture mode |
| `ENABLE_SUNSHINE` | `true` | Auto-start Sunshine game streaming server |
| `FORCE_X11_DUMMY_CONFIG` | `true` | Force dummy video driver (for headless) |

### Volumes

| Host Path | Container Path | Purpose |
|-----------|:--------------:|---------|
| `/mnt/user/appdata/cachyos` | `/home/cachyos` | Persistent user home |
| `/mnt/user/games` | `/mnt/games` | Game storage |

### Devices

| Device | Purpose |
|--------|---------|
| `/dev/dri` | Intel GPU passthrough (DRI + render nodes) |

### Recommended Docker Flags

| Flag | Why |
|------|-----|
| `--privileged` | GPU device access & DRI permissions |
| `--shm-size=2gb` | Prevents rendering glitches & tab crashes in Chromium/Electron |
| `--cap-add SYS_ADMIN` | Required by Sunshine for input injection |

---

## 📁 File Structure

```
cachyos-headless/
├── .github/
│   └── workflows/
│       └── docker-build.yml       # CI/CD pipeline
├── Dockerfile                     # Main image build
├── start.sh                       # Container entrypoint (runs cont-init.d scripts)
├── supervisord.conf                # Main supervisor config (includes supervisor.d/)
├── etc/
│   ├── cont-init.d/               # Runtime init scripts (like Steam-Headless)
│   │   ├── 10-setup_user.sh       # User, groups, sudo
│   │   ├── 30-configure_dbus.sh   # System D-Bus
│   │   ├── 60-configure_xorg.sh   # Xorg + dummy driver config
│   │   ├── 70-configure_steam.sh  # Steam autostart
│   │   ├── 80-configure_flatpak.sh # Flatpak remotes
│   │   └── 90-configure_gpu.sh    # Intel Arc GPU env vars
│   └── supervisor.d/              # Individual service configs
│       ├── xorg.ini               # Xorg server
│       ├── x11vnc.ini             # x11vnc (VNC server)
│       ├── desktop.ini            # XFCE4 desktop
│       ├── pipewire.ini           # PipeWire audio
│       ├── sunshine.ini           # Sunshine streaming
│       └── novnc.ini              # noVNC web frontend
├── usr/bin/
│   ├── common-functions.sh        # Shared helper functions
│   ├── start-xorg.sh             # Xorg launcher
│   ├── start-x11vnc.sh           # x11vnc launcher
│   ├── start-desktop.sh          # XFCE4 launcher
│   ├── start-pipewire.sh         # PipeWire launcher
│   ├── start-sunshine.sh          # Sunshine launcher
│   └── xfce4-minimise-all-windows # Window minimization helper
├── templates/
│   ├── xorg/
│   │   └── xorg.dummy.conf        # Dummy video driver config (headless)
│   └── sunshine/
│       ├── sunshine.conf          # Default Sunshine config
│       └── apps.json             # Default Sunshine apps (Desktop + Steam)
└── README.md                      ← you are here
```

---

## 🏗️ Service Architecture

All services are managed by `supervisord` with automatic restart on failure.
Startup uses the **cont-init.d pattern** (inspired by Steam-Headless):

```
  ENTRYPOINT: start.sh
      │
      ├── /etc/cont-init.d/*.sh   ← Runtime configuration (sequential)
      │     10-setup_user.sh
      │     30-configure_dbus.sh
      │     60-configure_xorg.sh
      │     70-configure_steam.sh
      │     80-configure_flatpak.sh
      │     90-configure_gpu.sh
      │
      └── supervisord             ← Service management (parallel)
            │
            ├── xorg (priority 20)        Real X server with GPU acceleration
            │     └── Xorg +GLX +RENDER +RANDR +Composite
            │
            ├── x11vnc (priority 30)      Shares Xorg display over VNC
            │     └── x11vnc -display :1
            │
            ├── novnc (priority 30)       Browser-based VNC client
            │     └── websockify :8080 → :5901
            │
            ├── pipewire (priority 40)    Audio server
            │     └── pipewire + pipewire-pulse
            │
            ├── desktop (priority 50)     XFCE4 desktop environment
            │     └── startxfce4 (waits for X)
            │
            └── sunshine (priority 50)   Game streaming server
                  └── sunshine (waits for X + desktop)
```

> **Design note:** Unlike TigerVNC (which creates a software-rendered virtual X server), this setup uses a **real Xorg server** with GPU acceleration. `x11vnc` simply shares the real X display over VNC. This means Steam, games, and Sunshine get full hardware OpenGL/Vulkan support.

---

## 🎮 Intel Arc GPU Support

Out-of-the-box support for Intel Arc B580 and compatible hardware:

| Component | Driver |
|-----------|--------|
| OpenGL | **mesa-git** (bleeding-edge) |
| Vulkan | **mesa-git** (vulkan-intel) |
| VA-API (encode/decode) | **intel-media-driver** (`iHD`) |
| VA-API (fallback) | **libva-mesa-driver** |

### Verify GPU Access

```bash
docker exec -it CachyOS-Headless bash

# VA-API
vainfo

# Vulkan
vulkaninfo | grep deviceName

# OpenGL
glxinfo | grep "OpenGL renderer"
```

---

## 📦 Post-Install

Install additional software from inside the desktop:

```bash
# Update system
sudo pacman -Syu

# Flatpak apps
flatpak install flathub com.spotify.Client com.discordapp.Discord
```

---

## 🔨 Building

### Standard Build

```bash
git clone https://github.com/adam2893/cachyos-headless.git
cd cachyos-headless
docker build -t cachyos-headless:latest .
```

---

## 🔄 CI/CD

The GitHub Actions workflow (`docker-build.yml`) handles everything:

- ✅ **Automatic builds** on push to `main` and tagged releases (`v*`)
- 📅 **Weekly rebuilds** (Sunday midnight UTC) for latest CachyOS packages
- 🏷️ **Smart tags** — `latest`, branch name, semver (`v1.0.0`, `v1.0`, `v1`)
- ⚡ **Layer caching** via GitHub Actions cache for faster builds
- 📤 **GHCR publishing** to `ghcr.io/adam2893/cachyos-headless`

---

## ❓ Troubleshooting

| Problem | Fix |
|---------|-----|
| ⬛ **Black screen** | `docker logs CachyOS-Headless` — check Xorg started |
| 🎨 **No GPU accel** | Verify `--privileged` and `/dev/dri` mapping |
| 🔇 **No audio** | `docker exec CachyOS-Headless pactl info` |
| 🚫 **Permission denied** | `chown -R 1000:1000 /mnt/user/appdata/cachyos` on host |
| 🌐 **noVNC won't load** | `docker exec CachyOS-Headless supervisorctl status novnc` |
| 💥 **Won't start** | Remove stale locks: `rm -rf /mnt/user/appdata/cachyos/.vnc/*.pid` |
| 🎮 **Sunshine not streaming** | Ensure `--cap-add SYS_ADMIN` or `--privileged` |
| 🖥️ **Steam crashes** | Verify Xorg is running: `docker exec CachyOS-Headless xdpyinfo` |

---

## ⚠️ Known Limitations

- 🚫 **No systemd** — services managed via `supervisord` instead
- 👤 **Single-user** — not designed for multi-user setups
- 🦾 **x86-64-v3 only** — no ARM support (no Raspberry Pi / Apple Silicon)
- 📦 **~3–4 GB image** — XFCE + Mesa + Vulkan + Firefox + Sunshine
- 🖥️ **X11 only** — no Wayland support

---

## 🙏 Acknowledgements

| Project | Role |
|---------|------|
| [CachyOS](https://cachyos.org/) | High-performance Arch-based distro |
| [Steam-Headless](https://github.com/Steam-Headless/docker-steam-headless) | Architecture pattern (Xorg + x11vnc + cont-init.d + supervisord) |
| [noVNC](https://github.com/novnc/noVNC) | Browser-based VNC client |
| [Sunshine](https://github.com/LizardByte/Sunshine) | Open-source game streaming server |
| [x11vnc](https://github.com/LibVNC/x11vnc) | VNC server for real X displays |

---

## 📄 License

MIT
