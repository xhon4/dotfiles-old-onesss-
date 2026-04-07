#!/bin/bash
HYPR_SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

socat -U - "UNIX-CONNECT:$HYPR_SOCK" | while read -r event; do
    case "$event" in
        fullscreen>>1)
            pkill -SIGUSR1 waybar
            ;;
        fullscreen>>0)
            pkill -SIGUSR1 waybar
            ;;
    esac
done
