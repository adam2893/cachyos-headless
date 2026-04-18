#!/bin/bash
export XDG_RUNTIME_DIR="/run/user/1000"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export DISPLAY=:1
export LIBVA_DRIVER_NAME=iHD
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
export __GLX_VENDOR_LIBRARY_NAME=mesa
export MESA_GL_VERSION_OVERRIDE=4.6
exec vncserver :1 -geometry "${RESOLUTION:-1920x1080}" -depth "${DEPTH:-24}" -localhost no -rfbauth /home/cachyos/.config/tigervnc/passwd +extension GLX
