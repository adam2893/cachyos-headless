<div align="center">

<img src="https://cachyos.org/_astro/logo.DuMERIP6_qzDwT.svg" alt="CachyOS Logo" width="120" height="120">

# CachyOS Headless

### High-Performance Headless Gaming in a Container

**Inspired by [steam-headless](https://github.com/Steam-Headless/docker-steam-headless) by [Josh.5](https://github.com/Josh5)**

[![Docker](https://img.shields.io/badge/Docker-Container-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![CachyOS](https://img.shields.io/badge/CachyOS-Performance_Optimized-1793D1)](https://cachyos.org/)
[![Steam](https://img.shields.io/badge/Steam-Enabled-1B2838?logo=steam&logoColor=white)](https://store.steampowered.com/)
[![Sunshine](https://img.shields.io/badge/Sunshine-Streaming-FFB800?logo=sun&logoColor=black)](https://github.com/LizardByte/Sunshine)

</div>

---

## Overview

**CachyOS Headless** is a Dockerised headless gaming environment that runs the Steam Client (with Proton) inside a virtual X11 desktop, enabling high-performance remote game streaming from any server or NAS. It takes the proven foundation of the steam-headless project and rebuilds it on top of **CachyOS** - a high-performance Arch Linux distribution renowned for its aggressive compiler optimisations, custom gaming-tuned kernels, and bleeding-edge Mesa drivers.

Run your entire Steam library on a headless Linux box and stream it to any device in your home, all without ever attaching a monitor. Whether you are running on bare metal, a home server, Unraid, TrueNAS, or a cloud VM with a GPU, CachyOS Headless delivers lower latency, better frame pacing, and higher throughput compared to generic Debian-based containers thanks to its performance-optimised foundation.

---

## Why CachyOS?

Traditional headless Steam containers are built on Debian or Ubuntu, which use generic `x86-64` baseline package compilations and stock Linux kernels. **CachyOS Headless** swaps that foundation for something fundamentally faster:

| Feature | Debian-based Containers | CachyOS Headless |
|---|---|---|
| **CPU Optimisation** | Generic x86-64 baseline | x86-64-v3 / v4 with LTO, PGO, BOLT |
| **Kernel Scheduler** | Standard Linux scheduler | BORE scheduler (gaming-optimised) |
| **Mesa / GPU Drivers** | May lag behind releases | Bleeding-edge from Arch rolling repos |
| **Gaming Responsiveness** | Standard scheduling | Burst-oriented frame pacing |
| **Package Freshness** | Fixed release cadence | Rolling release - always latest |
| **AUR Access** | Not available | Full AUR access for bleeding-edge tools |

### The BORE Scheduler Advantage

The **BORE (Burst-Oriented Response Enhancer)** scheduler is a custom patch set built on top of EEVDF that is specifically tuned for interactive and bursty workloads like gaming. It delivers smoother frame times, reduced input latency, and improved responsiveness under load compared to the default Linux scheduler, making it the ideal choice for a headless gaming container.

---

## Features

- **Steam Client with Proton** - Full Steam Linux client pre-configured with Proton for Windows game compatibility
- **Sunshine / Moonlight Streaming** - Built-in Sunshine server for ultra-low-latency game streaming via Moonlight clients (NVIDIA GameStream compatible)
- **noVNC Web UI** - Browser-based access to the Xfce4 desktop environment for management and configuration
- **Multi-GPU Support** - NVIDIA, AMD, and Intel GPU passthrough with per-GPU PCI device isolation
- **Controller Support** - Full gamepad / controller passthrough for wired and wireless devices
- **Steam Remote Play** - Can act as a Steam Remote Play host for streaming to other Steam clients
- **Flatpak & AppImage** - Install additional game launchers (Heroic, Lutris, EmuDeck) via Flatpak
- **SSH Access** - Built-in SSH server on port `2222` for remote administration
- **Auto-start Scripts** - Drop `.sh` scripts into `~/init.d` to execute on container startup
- **Root Access** - Full `sudo` access inside the container for advanced configuration
- **GameMode & MangoHud** - Pre-installed Feral GameMode and MangoHud for performance monitoring and optimisation

---

## Quick Start

### Prerequisites

- Docker Engine 20.10+ with [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) (for NVIDIA GPUs)
- A GPU (NVIDIA, AMD, or Intel) with working drivers on the host
- [Moonlight](https://moonlight-stream.org/) client on your streaming device

### Pull & Run (NVIDIA)

```bash
docker run -d \
  --name=cachyos-headless \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e MODE=primary \
  -e TZ=Australia/Sydney \
  -e USER_PASSWORD=yourpassword \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 47984-47990:47984-47990/tcp \
  -p 48010:48010/tcp \
  -p 47989:47989/udp \
  -p 47998-48000:47998-48000/udp \
  -p 8083:8083/tcp \
  -p 2222:2222/tcp \
  -v /path/to/steam:/home/user/Steam \
  -v /path/to/config:/home/user/.config \
  adam2893/cachyos-headless:latest
```

### Docker Compose (NVIDIA)

```yaml
services:
  cachyos-headless:
    image: adam2893/cachyos-headless:latest
    container_name: cachyos-headless
    restart: unless-stopped
    environment:
      - MODE=primary
      - TZ=Australia/Sydney
      - USER_PASSWORD=yourpassword
      - PUID=1000
      - PGID=1000
    volumes:
      - ./steam:/home/user/Steam
      - ./config:/home/user/.config
    ports:
      # Sunshine streaming ports
      - 47984-47990:47984-47990/tcp
      - 48010:48010/tcp
      - 47989:47989/udp
      - 47998-48000:47998-48000/udp
      # noVNC web UI
      - 8083:8083/tcp
      # SSH
      - 2222:2222/tcp
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

### AMD / Intel GPU

Replace the GPU deployment section with device mounts:

```yaml
    devices:
      - /dev/dri:/dev/dri
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `MODE` | `primary` | GPU mode: `primary` or `secondary` |
| `TZ` | `UTC` | Timezone (e.g. `Australia/Sydney`) |
| `USER_PASSWORD` | `password` | Password for the container user |
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |
| `DISPLAY` | `:0` | Virtual display number |
| `WEBUI_PORT` | `8083` | Port for the noVNC web interface |
| `SSH_PORT` | `2222` | Port for the SSH server |

---

## Ports

| Port | Protocol | Service |
|---|---|---|
| `47984-47990` | TCP | Sunshine streaming |
| `48010` | TCP | Sunshine control |
| `47989` | UDP | Sunshine streaming |
| `47998-48000` | UDP | Sunshine streaming |
| `8083` | TCP | noVNC web UI |
| `2222` | TCP | SSH server |
| `32123` | TCP | Web audio stream |

---

## Connecting

### Game Streaming (Recommended)

1. Open the [noVNC Web UI](http://localhost:8083) in your browser to set up Sunshine
2. Pair your Moonlight client with the container's IP address
3. Launch games through Moonlight for ultra-low-latency streaming

### noVNC Web Access

Open `http://<your-server-ip>:8083` in any modern browser for a full remote desktop experience with audio support.

### SSH Access

```bash
ssh user@<your-server-ip> -p 2222
```

---

## Volumes

| Host Path | Container Path | Description |
|---|---|---|
| `./steam` | `/home/user/Steam` | Steam library and game data |
| `./config` | `/home/user/.config` | Application configuration files |

You can add additional volume mounts for game storage, ROMs, or other media as needed.

---

## Building from Source

```bash
git clone https://github.com/adam2893/cachyos-headless.git
cd cachyos-headless
docker build -t adam2893/cachyos-headless:latest .
```

---

## Acknowledgements

- [**Josh.5 / steam-headless**](https://github.com/Steam-Headless/docker-steam-headless) - The original project that inspired this container
- [**CachyOS**](https://cachyos.org/) - The high-performance Arch Linux distribution that forms the foundation
- [**Sunshine**](https://github.com/LizardByte/Sunshine) - Game streaming server (NVIDIA GameStream compatible)
- [**Moonlight**](https://moonlight-stream.org/) - Game streaming client
- [**Valve / Steam**](https://store.steampowered.com/) - Steam Client and Proton compatibility layer

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.
