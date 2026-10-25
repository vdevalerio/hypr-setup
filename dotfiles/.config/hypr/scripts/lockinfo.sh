#!/usr/bin/env bash
# Lock screen texts (hyprlock.conf): lockinfo.sh greeting | music | battery
esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; echo "${s//>/&gt;}"; }

case "$1" in
    greeting)
        h=$(date +%-H)
        if   (( h < 5 ));  then g="Good night"
        elif (( h < 12 )); then g="Good morning"
        elif (( h < 18 )); then g="Good afternoon"
        else                    g="Good evening"; fi
        name=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1 | awk '{print $1}')
        echo "$g, ${name:-$USER}"
        ;;
    music)
        [ "$(playerctl status 2>/dev/null)" = Playing ] || exit 0
        t=$(playerctl metadata --format '{{title}}' 2>/dev/null | cut -c1-48)
        a=$(playerctl metadata --format '{{artist}}' 2>/dev/null | cut -c1-32)
        echo "󰎈  $(esc "$t")${a:+  <span alpha=\"60%\">$(esc "$a")</span>}"
        ;;
    battery)
        b=/sys/class/power_supply/BAT*
        cap=$(cat $b/capacity 2>/dev/null | head -1) || exit 0
        [ -n "$cap" ] || exit 0
        if [ "$(cat $b/status 2>/dev/null | head -1)" = Charging ]; then icon=󰂄
        else icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹); icon=${icons[$(( cap >= 100 ? 9 : cap / 10 ))]}; fi
        echo "$icon  $cap%"
        ;;
esac
