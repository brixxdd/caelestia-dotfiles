#!/bin/bash
# Lanza Waydroid — reinicia automáticamente si está trabado

STATUS=$(waydroid status 2>/dev/null | grep "Container:" | awk '{print $2}')

if [[ "$STATUS" != "RUNNING" ]]; then
    # Container caído o trabado — reinicio completo
    waydroid session stop 2>/dev/null
    sudo systemctl stop waydroid-container.service 2>/dev/null
    sudo killall -9 waydroid 2>/dev/null
    sudo lxc-stop -n waydroid 2>/dev/null
    sleep 2
    sudo systemctl start waydroid-container.service
    sleep 3
    WAYLAND_DISPLAY=wayland-1 waydroid session start &>/dev/null &
    sleep 4
fi

waydroid show-full-ui
