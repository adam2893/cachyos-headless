#!/usr/bin/env bash
###
# File: start-xorg.sh
# Description: Start the real Xorg server with GPU acceleration
# Adapted from Steam-Headless/docker-steam-headless
###
set -e
source /usr/bin/common-functions.sh

# CATCH TERM SIGNAL:
_term() {
    kill -TERM "$xorg_pid" 2>/dev/null
}
trap _term SIGTERM SIGINT

# EXECUTE PROCESS:
# Run X server with GPU acceleration
# In a Docker container, we may not have a real VT, so use vtXX only if available
vt_arg=""
if [ -e /dev/tty7 ]; then
    vt_arg="vt7"
elif [ -e /dev/tty1 ]; then
    vt_arg="vt1"
fi

/usr/bin/Xorg \
    -ac \
    -noreset \
    -novtswitch \
    -sharevts \
    +extension RANDR \
    +extension RENDER \
    +extension GLX \
    +extension XVideo \
    +extension DOUBLE-BUFFER \
    +extension DAMAGE \
    +extension Composite \
    -dpms \
    -s off \
    -nolisten tcp \
    -iglx \
    -verbose \
    ${vt_arg} \
    "${DISPLAY:?}" &
xorg_pid=$!

echo "Xorg started on display ${DISPLAY} with PID ${xorg_pid}"

# WAIT FOR CHILD PROCESS:
wait "$xorg_pid"
