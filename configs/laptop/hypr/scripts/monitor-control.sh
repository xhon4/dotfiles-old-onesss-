#!/usr/bin/env bash
# ─────────────────────────────────────────
# hyprland-ricing by occhi
# ~/.config/hypr/scripts/monitor-control.sh
# ─────────────────────────────────────────
# Turns off the screen after 5 min of inactivity via swayidle.
# Note: hypridle (hypridle.conf) is the native Hyprland alternative.
#
# Option A — hypridle (recommended, config at ~/.config/hypr/hypridle.conf)
# Option B — swayidle (this script, more universal)
#
# Dependencies: swayidle, playerctl, hyprctl
# Install:      pacman -S swayidle playerctl

IDLE_LIMIT=300  # seconds

swayidle -w \
    timeout $IDLE_LIMIT '
        if ! playerctl status 2>/dev/null | grep -q "Playing"; then
            hyprctl dispatch dpms off
        fi
    ' \
    resume 'hyprctl dispatch dpms on'
