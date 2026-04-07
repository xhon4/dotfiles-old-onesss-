MAXLEN=40

player=$(playerctl --list-all 2>/dev/null | grep -i "spotify" | head -n1 | tr -d '[:space:]')

if [ -z "$player" ]; then
    echo '{"text": "󰝛  No Music :c", "class": "stopped", "tooltip": ""}'
    exit
fi

status=$(playerctl --player="$player" status 2>/dev/null)

if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
    artist=$(playerctl --player="$player" metadata artist 2>/dev/null)
    title=$(playerctl --player="$player" metadata title 2>/dev/null)

    if [ -z "$title" ] || [ -z "$artist" ]; then
        echo '{"text": "󰝛 No Music :c", "class": "stopped", "tooltip": ""}'
        exit
    fi

    full="$artist - $title"
    if [ ${#full} -gt $MAXLEN ]; then
        full="${full:0:$MAXLEN}..."
    fi

    prev=""
    next=""

    class="playing"
    [ "$status" == "Paused" ] && class="paused"

    text_escaped=$(echo "$prev   $full   $next" | sed 's/"/\\"/g')
    tooltip_escaped=$(echo "$full" | sed 's/"/\\"/g')

    echo "{\"text\": \"$text_escaped\", \"class\": \"$class\", \"tooltip\": \"$tooltip_escaped\"}"
else
    echo '{"text": "󰝛 No Music :c", "class": "stopped", "tooltip": ""}'
fi
