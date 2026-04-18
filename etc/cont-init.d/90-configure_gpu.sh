#!/usr/bin/env bash
###
# File: 90-configure_gpu.sh
# Description: Configure GPU environment variables for Intel Arc B580
###
source /usr/bin/common-functions.sh

print_header "Configure GPU"

# Intel Arc B580 GPU environment
# Let Mesa auto-detect the correct driver (do NOT override with iris)
export LIBVA_DRIVER_NAME=iHD
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
export __GLX_VENDOR_LIBRARY_NAME=mesa
export MESA_GL_VERSION_OVERRIDE=4.6

# Write GPU env to a file so other scripts can source it
cat > /tmp/.gpu-env <<EOF
export LIBVA_DRIVER_NAME=iHD
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
export __GLX_VENDOR_LIBRARY_NAME=mesa
export MESA_GL_VERSION_OVERRIDE=4.6
EOF

print_step "GPU env configured for Intel Arc (iHD + Mesa auto-detect)"

echo -e "\e[34mDONE\e[0m"
