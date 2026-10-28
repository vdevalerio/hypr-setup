#!/usr/bin/env bash
# Now-playing music for Waybar's custom/media module (JSON, one line per change).
# Runs playerctl outside Waybar: the built-in "mpris" module froze the bar when a player
# (e.g. a browser tab with video) appeared or disappeared.
playerctl --follow metadata --format '{{status}}	{{playerName}}	{{title}}	{{artist}}' 2>/dev/null |
while IFS=$'\t' read -r status player title artist; do
    if [ -z "$status" ] || [ "$status" = Stopped ] || [ -z "$title" ]; then
        echo '{"text": ""}'
        continue
    fi
    [ "$status" = Playing ] && icon=󰐊 || icon=󰏤
    tip="$player: $title${artist:+ — $artist}"
    # shorter title with a bigger font (look.sh), so the right end of the bar is not pushed off screen
    font=$(sed -n 's/^font=//p' ~/.config/hypr/look.conf 2>/dev/null); max=$(( 2400 / ${font:-100} ))
    (( max < 12 )) && max=12
    (( ${#title} > max )) && title="${title:0:max-1}…"
    jq -cn --arg text "$icon  $title" --arg tip "$tip" --arg class "${status,,}" \
        '{text: $text, tooltip: ($tip + "\nClick: play/pause · Right click: next · Scroll: previous/next"), class: $class}'
done
