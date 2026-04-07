#!/usr/bin/env bash
# ─────────────────────────────────────────
# hyprland-ricing by occhi
# ~/.config/hypr/scripts/waybar-fullscreen.sh
# ─────────────────────────────────────────
# Toggles waybar visibility when a window enters or exits fullscreen.
# Sends SIGUSR1 to waybar to trigger its hide/show toggle.

HYPR_SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

socat -U - "UNIX-CONNECT:$HYPR_SOCK" | while read -r event; do
    case "$event" in
        fullscreen>>1|fullscreen>>0)
            pkill -SIGUSR1 waybar
            ;;
    esac
done
