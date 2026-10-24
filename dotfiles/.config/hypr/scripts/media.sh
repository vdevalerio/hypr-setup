#!/usr/bin/env bash
# Música tocando agora, para o módulo custom/media da Waybar (JSON, uma linha por mudança).
# Roda o playerctl fora da Waybar: o módulo "mpris" embutido travava a barra quando um player
# (ex.: aba do navegador com vídeo) aparecia ou sumia.
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
