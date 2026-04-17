<p align="center">
  <img src="https://cachyos.org/_astro/logo.DuMERIP6_qzDwT.svg" alt="CachyOS" width="120"/>
</p>

<h1 align="center">CachyOS Headless</h1>

<p align="center">
  <strong>A headless CachyOS desktop in Docker — access via VNC or browser</strong><br/>
  <sub>Built for Unraid · Intel Arc GPU ready · Inspired by
    <a href="https://github.com/Steam-Headless/docker-steam-headless">Steam-Headless</a>
  </sub>
</p>

<p align="center">
  <a href="https://ghcr.io"><img src="https://img.shields.io/badge/registry-ghcr.io-blue?logo=github" alt="GHCR"/></a>
  <a href="https://hub.docker.com/r/cachyos/cachyos-v3"><img src="https://img.shields.io/badge/base-cachyos%2Fcachyos--v3-orange?logo=linux" alt="Base Image"/></a>
  <a href="https://cachyos.org"><img src="https://img.shields.io/badge/distro-CachyOS-blue?logo=arch-linux" alt="CachyOS"/></a>
  <a href="https://xfce.org"><img src="https://img.shields.io/badge/desktop-XFCE4-blue?logo=xfce" alt="XFCE4"/></a>
  <a href="https://tigervnc.org"><img src="https://img.shields.io/badge/VNC-TigerVNC-green?logo=vnc" alt="TigerVNC"/></a>
  <a href="https://github.com/novnc/noVNC"><img src="https://img.shields.io/badge/web%20client-noVNC-9cf?logo=firefox-browser" alt="noVNC"/></a>
  <a href="https://pipewire.org"><img src="https://img.shields.io/badge/audio-PipeWire-purple?logo=linux" alt="PipeWire"/></a>
  <br/><br/>
  <img src="https://img.shields.io/badge/arch-linux%2Famd64-x86__64__v3-informational" alt="x86-64-v3"/>
  <img src="https://img.shields.io/badge/gpu-intel%20arc-green?logo=intel" alt="Intel Arc"/>
</p>

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🐧 **CachyOS Base** | Built on `cachyos/cachyos-v3` — Arch-based with BORE scheduler & x86-64-v3 optimisations |
| 🖥️ **XFCE4 Desktop** | Full lightweight desktop with Thunar file manager and system utilities |
| 🔗 **Dual Access** | Native VNC (port `5901`) **and** browser-based noVNC (port `8080`) |
| 🎮 **Intel GPU Support** | Mesa, VA-API (`iHD`), Vulkan — optimised for Intel Arc B580 |
| 🔊 **PipeWire Audio** | Modern audio stack with PulseAudio compatibility (`pipewire-pulse`) |
| 🔄 **Auto-Restart** | All services managed via `supervisord` with automatic recovery |
| 📦 **Flatpak Ready** | Install additional apps (Spotify, Discord, etc.) at runtime |
| 💾 **Persistent Storage** | Home directory and game storage survive container restarts |

---

## 🚀 Quick Start

### Pull

```bash
docker pull ghcr.io/<your-username>/cachyos-headless:latest
```

### Docker Compose

```yaml
services:
  cachyos-headless:
    image: ghcr.io/<your-username>/cachyos-headless:latest
    container_name: CachyOS-Headless
    privileged: true
    shm_size: '2gb'
    ports:
      - "5901:5901"   # VNC
      - "8080:8080"   # noVNC (browser)
    volumes:
      - /mnt/user/appdata/cachyos:/home/cachyos   # persistent home
      - /mnt/user/games:/mnt/games                 # game storage
    devices:
      - /dev/dri:/dev/dri                          # Intel GPU passthrough
    environment:
      - USER=cachyos
      - PASSWD=cachyos
      - LIBVA_DRIVER_NAME=iHD
    restart: unless-stopped
```

### Docker CLI

```bash
docker run -d \
  --name CachyOS-Headless \
  --privileged \
  --shm-size=2gb \
  -p 5901:5901 -p 8080:8080 \
  -v /mnt/user/appdata/cachyos:/home/cachyos \
  -v /mnt/user/games:/mnt/games \
  -e USER=cachyos -e PASSWD=cachyos \
  -e LIBVA_DRIVER_NAME=iHD \
  ghcr.io/<your-username>/cachyos-headless:latest
```

### Connect

| Method | Address | Default Password |
|--------|---------|:----------------:|
| 🖥️ **VNC Client** (TigerVNC, RealVNC, Remmina) | `<your-ip>:5901` | `cachyos` |
| 🌐 **Browser** (noVNC) | `http://<your-ip>:8080/vnc.html` | `cachyos` |

---

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|:-------:|-------------|
| `USER` | `cachyos` | Desktop username |
| `PASSWD` | `cachyos` | VNC & user password (set at runtime) |
| `DISPLAY` | `:1` | X11 display number |
| `RESOLUTION` | `1920x1080` | Desktop resolution |
| `DEPTH` | `24` | Colour depth |
| `PUID` | `1000` | User UID |
| `PGID` | `1000` | User GID |
| `LIBVA_DRIVER_NAME` | `iHD` | VA-API driver for Intel GPU |
| `TERM` | `xterm` | Terminal type |

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

---

## 📁 File Structure

```
cachyos-headless/
├── .github/
│   └── workflows/
│       └── docker-build.yml       # CI/CD pipeline
├── Dockerfile                     # Main image
├── Dockerfile.diagnostic          # Step-by-step build (debugging)
├── supervisord.conf               # Service orchestration
├── start.sh                       # Container entrypoint
└── README.md                      ← you are here
```

---

## 🏗️ Service Architecture

All services are managed by `supervisord` with automatic restart on failure:

```
 ┌─────────────────────────────────────────────────┐
 │                  supervisord                     │
 │                                                  │
 │  Priority 10   PipeWire (audio server)          │
 │  Priority 11   PipeWire-Pulse (PA compat)        │
 │  Priority 12   WirePlumber (session manager)     │
 │  Priority 20   TigerVNC (X server + VNC :1)      │
 │  Priority 30   XFCE4 (desktop environment)       │
 │  Priority 40   noVNC / websockify (port 8080)    │
 └─────────────────────────────────────────────────┘
```

> **Design note:** TigerVNC is both the X server and VNC server — no separate Xvfb or x11vnc needed, eliminating the port conflicts common in other setups.

---

## 🎮 Intel Arc GPU Support

Out-of-the-box support for Intel Arc B580 and compatible hardware:

| Component | Driver |
|-----------|--------|
| OpenGL | **Mesa** |
| Vulkan | **vulkan-intel** |
| VA-API (encode/decode) | **intel-media-driver** (`iHD`) |
| VA-API (fallback) | **libva-mesa-driver** |

### Verify GPU Access

```bash
docker exec -it CachyOS-Headless bash

# VA-API
vainfo

# Vulkan
vulkaninfo | grep deviceName
```

### Change Resolution

```bash
docker exec CachyOS-Headless xrandr --output VNC-0 --mode 2560x1440
```

---

## 📦 Post-Install

Install additional software from inside the desktop:

```bash
# Update system
sudo pacman -Syu

# Steam with CachyOS gaming optimisations
sudo pacman -S steam cachyos-gaming-meta

# Flatpak apps
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install spotify discord
```

---

## 🔨 Building

### Standard Build

```bash
git clone https://github.com/<your-username>/cachyos-headless.git
cd cachyos-headless
docker build -t cachyos-headless:latest .
```

### Debug Build Failure

If a package fails during `docker build`, use the diagnostic Dockerfile to find exactly which one:

```bash
docker build --progress=plain -f Dockerfile.diagnostic -t cachyos-test . 2>&1 | tee build.log
```

Search `build.log` for the last `=== [N/18] DONE ===` — the next step is the one that broke.

---

## 🔄 CI/CD

The GitHub Actions workflow (`docker-build.yml`) handles everything:

- ✅ **Automatic builds** on push to `main` and tagged releases (`v*`)
- 📅 **Weekly rebuilds** (Sunday midnight UTC) for latest CachyOS packages
- 🏷️ **Smart tags** — `latest`, branch name, semver (`v1.0.0`, `v1.0`, `v1`)
- ⚡ **Layer caching** via GitHub Actions cache for faster builds
- 📤 **GHCR publishing** to `ghcr.io/<your-username>/cachyos-headless`

| Repo Visibility | Pull Auth |
|:---------------:|-----------|
| **Public** | None required (100 pulls/hr/IP) |
| **Private** | GitHub PAT with `read:packages` |

---

## ❓ Troubleshooting

| Problem | Fix |
|---------|-----|
| ⬛ **Black screen** | `docker logs CachyOS-Headless` — check XFCE started |
| 🎨 **No GPU** | Verify `--privileged` and `/dev/dri` mapping |
| 🔇 **No audio** | `docker exec CachyOS-Headless pactl info` |
| 🚫 **Permission denied** | `chown -R 1000:1000 /mnt/user/appdata/cachyos` on host |
| 🌐 **noVNC won't load** | `docker exec CachyOS-Headless supervisorctl status novnc` |
| 💥 **Won't start** | `rm -rf /mnt/user/appdata/cachyos/.vnc/*.pid` (stale locks) |

---

## ⚠️ Known Limitations

- 🚫 **No systemd** — services managed via `supervisord` instead
- 👤 **Single-user** — not designed for multi-user setups
- 🦾 **x86-64-v3 only** — no ARM support (no Raspberry Pi / Apple Silicon)
- 📦 **~3–4 GB image** — XFCE + Mesa + Vulkan + Firefox
- 🖥️ **X11 only** — no Wayland support

---

## 🙏 Acknowledgements

| Project | Role |
|---------|------|
| [CachyOS](https://cachyos.org/) | High-performance Arch-based distro |
| [Steam-Headless](https://github.com/Steam-Headless/docker-steam-headless) | Headless desktop container pattern |
| [noVNC](https://github.com/novnc/noVNC) | Browser-based VNC client |
| [TigerVNC](https://tigervnc.org/) | High-performance VNC server |

---

## 📄 License

MIT
