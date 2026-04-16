#!/bin/bash
set -e

chown -R cachyos:cachyos /home/cachyos

if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/card* 2>/dev/null || true
    chmod 666 /dev/dri/render* 2>/dev/null || true
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
