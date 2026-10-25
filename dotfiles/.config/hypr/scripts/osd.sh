#!/usr/bin/env bash
# OSD (quick notification with a bar) for volume, microphone and Caps Lock, via swaync — same as the brightness one.
#
#   osd.sh volume up|down|mute [passo]
#   osd.sh mic mute
#   osd.sh caps                   (called when Caps Lock is released; reads the LED state)
#
# Each type reuses the same notification (-r), so holding the key doesn't stack notifications.

STEP=5
CACHE="${XDG_RUNTIME_DIR:-/tmp}/osd"
mkdir -p "$CACHE"

notify() { # notify <type> <title> <text> [value 0-100]
    local id args=(-a osd -t 1200 -p)
    id=$(cat "$CACHE/$1" 2>/dev/null)
    [ -n "$id" ] && args+=(-r "$id")
    [ -n "$4" ] && args+=(-h "int:value:$4")
    notify-send "${args[@]}" "$2" "$3" > "$CACHE/$1" 2>/dev/null
}

# "Volume: 0.45 [MUTED]" → "45 1"
read_vol() { wpctl get-volume "$1" | awk '{printf "%d %d\n", $2 * 100 + 0.5, /MUTED/}'; }

volume() {
    local sink=@DEFAULT_AUDIO_SINK@ v muted icon
    case $1 in
        up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1 "$sink" "${2:-$STEP}%+" ;;
        down) wpctl set-volume "$sink" "${2:-$STEP}%-" ;;
        mute) wpctl set-mute "$sink" toggle ;;
    esac
    read -r v muted < <(read_vol "$sink")
    if (( muted )) || (( v == 0 )); then icon=$'\U000f075f'
    elif (( v < 34 )); then icon=$'\U000f057f'
    elif (( v < 67 )); then icon=$'\U000f0580'
    else icon=$'\U000f057e'; fi
    if (( muted )); then notify volume "$icon  Volume" "Muted" 0
    else notify volume "$icon  Volume" "$v%" "$v"; fi
}

mic() {
    local src=@DEFAULT_AUDIO_SOURCE@ v muted
    wpctl set-mute "$src" toggle
    read -r v muted < <(read_vol "$src")
    if (( muted )); then notify mic $'\U000f036d  Microphone' "Muted"
    else notify mic $'\U000f036c  Microphone' "On ($v%)"; fi
}

caps() {
    local led on=0
    for led in /sys/class/leds/*::capslock/brightness; do
        [ -r "$led" ] && (( $(cat "$led") > 0 )) && on=1
    done
    if (( on )); then notify caps $'\U000f0632  Caps Lock' "ON"
    else notify caps $'\U000f0632  Caps Lock' "off"; fi
}

case $1 in
    volume) volume "$2" "$3" ;;
    mic)    mic ;;
    caps)   caps ;;
    *) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
