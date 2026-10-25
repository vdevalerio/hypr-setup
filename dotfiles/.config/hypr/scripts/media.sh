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
    (( ${#title} > 32 )) && title="${title:0:31}…"
    jq -cn --arg text "$icon  $title" --arg tip "$tip" --arg class "${status,,}" \
        '{text: $text, tooltip: ($tip + "\nClick: play/pause · Right click: next · Scroll: previous/next"), class: $class}'
done
