#!/usr/bin/env bash
# Wacom / stylus tablets: which screen the pen is mapped to (Hyprland input:tablet:output).
#   tablet.sh map <monitor>   map the pen to that monitor (e.g. eDP-1, HDMI-A-2)
#   tablet.sh map focused     map it to the monitor that has focus now
#   tablet.sh map all         span every monitor
#   tablet.sh list            connected tablets and tools
# Lasts until the next config reload; the permanent default is input.tablet.output in hyprland.lua.
case "${1:-}" in
    map)
        t=${2:?monitor name, "focused" or "all"}
        case $t in
            focused) t=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name') ;;
            all) t="" ;;
        esac
        hyprctl eval "hl.config({ input = { tablet = { output = '$t' } } })" >/dev/null
        notify-send -a tablet "Pen mapped to ${t:-all monitors}" ;;
    list) hyprctl devices -j | jq -r '.tablets[] | "\(.type // "tablet")\t\(.name // .address)"' ;;
    *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
