#!/usr/bin/env bash
# ─────────────────────────────────────────
# hyprland-ricing by occhi
# ~/.config/hypr/scripts/toggle_desktop.sh
# ─────────────────────────────────────────
# Moves all windows on the active workspace to a special workspace
# and back, effectively toggling a "show desktop" state.

STATE_FILE="/tmp/hypr_hidden_state"
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

if [ -f "$STATE_FILE" ]; then
    while IFS='|' read -r addr ws; do
        hyprctl dispatch movetoworkspacesilent "$ws,address:$addr"
    done < "$STATE_FILE"
    rm "$STATE_FILE"
else
    hyprctl clients -j \
        | jq -r --argjson ws "$CURRENT_WS" \
            '.[] | select(.workspace.id == $ws) | "\(.address)|\(.workspace.id)"' \
        > "$STATE_FILE"

    while IFS='|' read -r addr ws; do
        hyprctl dispatch movetoworkspacesilent "special:desktop,address:$addr"
    done < "$STATE_FILE"
fi
