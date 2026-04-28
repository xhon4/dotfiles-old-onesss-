#!/bin/bash
# oxh-hyprland-dotfiles by occhi

EMOTE_FILE="$HOME/.config/rofi/emotes.txt"
STATS_FILE="$HOME/.config/rofi/scripts/emote_stats.txt"

touch "$STATS_FILE"

TOP_5=$(sort -rn "$STATS_FILE" | head -n 5 | cut -d'|' -f2-)
ALL_EMOTES=$(cat "$EMOTE_FILE")
MENU_CONTENT=$(echo -e "$TOP_5\n$ALL_EMOTES" | awk '!x[$0]++')

SELECTED=$(echo -e "$MENU_CONTENT" | rofi -dmenu \
    -p " oxh " \
    -i \
    -theme-str '
        window { 
            width: 450px; 
            border: 2px; 
            border-color: #333333; 
            background-color: #111111;
        }
        mainbox { padding: 5px; }
        inputbar { enabled: false; }
        listview { 
            columns: 5; 
            lines: 4; 
            cycle: false; 
            dynamic: true; 
            layout: vertical;
            fixed-columns: true;
            spacing: 3px;
        }
        element {
            orientation: vertical;
            padding: 8px 2px;
            border-radius: 2px;
            background-color: #111111;
        }
        element-text {
            horizontal-align: 0.5;
            font: "JetBrainsMono Nerd Font 9.3";
            color: #bbbbbb;
        }
        element selected {
            background-color: #333333;
            border: 1px;
            border-color: #555555;
        }
        element-text selected {
            color: #ffffff;
        }
    ')

if [ -n "$SELECTED" ]; then
    echo -n "$SELECTED" | wl-copy
    if command -v wtype &> /dev/null; then
        sleep 0.1 && wtype "$SELECTED"
    fi

    if grep -qF "|$SELECTED" "$STATS_FILE"; then
        awk -v sel="$SELECTED" 'BEGIN{FS=OFS="|"} $2==sel{$1=$1+1} 1' \
            "$STATS_FILE" > "${STATS_FILE}.tmp" && mv "${STATS_FILE}.tmp" "$STATS_FILE"
    else
        echo "1|$SELECTED" >> "$STATS_FILE"
    fi
fi