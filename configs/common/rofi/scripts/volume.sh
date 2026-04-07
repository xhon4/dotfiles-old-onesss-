#!/bin/bash
# Volume control script using pamixer and dunstify

# Icon directory (Ensure your .png files are moved here in the repo)
vol_dir="$HOME/.config/hypr/assets"

# Notification function
notify() {
    dunstify -u low -h string:x-dunst-stack-tag:cvolum "$@"
}

# Get current volume status
get_volume() {
    status=$(pamixer --get-volume-human)
    if [ "$status" = "muted" ]; then
        echo "muted"
    else
        echo "$status" | sed 's/%//'
    fi
}

# Determine the icon based on volume status
get_icon() {
    current_vol=$(get_volume)
    if [ "$current_vol" = "muted" ] || [ "$current_vol" -eq 0 ]; then
        icon="$vol_dir/mute.png"
    else
        icon="$vol_dir/vol.png"
    fi
}

# Show a notification with the current volume
show_notification() {
    get_icon
    message="Volume: $(get_volume)"
    echo "$message" | grep -q "muted" || message="${message}%"
    notify -i "$icon" "$message"
}

# Adjust the volume (increase or decrease)
adjust_volume() {
    pamixer --unmute
    pamixer --allow-boost --set-limit 150 "$@"
    show_notification
}

# Toggle mute/unmute
toggle_mute() {
    pamixer --toggle-mute
    get_icon
    if [ "$(pamixer --get-mute)" = "true" ]; then
        message="Muted"
    else
        message="Unmuted"
    fi
    notify -i "$icon" "$message"
}

# Handle user input
case $1 in
    --get)      get_volume ;;
    --inc)      adjust_volume -i 5 ;;
    --dec)      adjust_volume -d 5 ;;
    --toggle)   toggle_mute ;;
    *)          echo "$(get_volume)%" ;;
esac