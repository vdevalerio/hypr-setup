#!/usr/bin/env bash
# Menu de energia (SUPER + X ou botão na barra)
lock=$'  Lock'
logout=$'  Log out'
suspend=$'  Suspend'
reboot=$'  Reboot'
shutdown=$'  Shut down'

pkill -x rofi && exit 0
choice=$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" |
    rofi -dmenu -i -p "Power" -theme-str 'window {width: 320px;} listview {lines: 5;}')

case "$choice" in
    "$lock")     loginctl lock-session ;;
    "$suspend")  systemctl suspend ;;
    "$logout")   hyprshutdown || hyprctl dispatch 'hl.dsp.exit()' ;;
    "$reboot")   systemctl reboot ;;
    "$shutdown") systemctl poweroff ;;
esac
