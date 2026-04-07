#!/usr/bin/env bash
# ─────────────────────────────────────────
# hyprland-ricing by occhi
# ~/.config/hypr/scripts/power_menu.sh
# ─────────────────────────────────────────

options="󰍁 Lock
󰒲 Suspend
󰗽 Logout
󰜉 Reboot
󰐥 Shutdown"

rofi_cmd() {
    rofi -dmenu \
        -p "Goodbye ${USER}" \
        -mesg "Uptime: $(uptime -p | sed 's/up //')" \
        -theme "$HOME/.config/rofi/PowerMenu.rasi"
}

chosen=$(printf "%s\n" "$options" | rofi_cmd)

case "$chosen" in
    "󰐥 Shutdown") systemctl poweroff ;;
    "󰜉 Reboot")   systemctl reboot ;;
    "󰍁 Lock")     hyprlock ;;
    "󰒲 Suspend")  systemctl suspend ;;
    "󰗽 Logout")   hyprctl dispatch exit ;;
esac
