#!/usr/bin/env bash
# Power menu (SUPER + X or the bar button). "Reload Hyprland" re-reads the config without closing anything.
lock=$'  Lock'
reload=$'\U000F0450  Reload Hyprland'
logout=$'  Log out'
suspend=$'  Suspend'
reboot=$'  Reboot'
shutdown=$'  Shut down'

pkill -x rofi && exit 0
choice=$(printf '%s\n' "$lock" "$reload" "$suspend" "$logout" "$reboot" "$shutdown" |
    rofi -dmenu -i -p "Power" -theme-str 'window {width: 320px;} listview {lines: 6;}')

case "$choice" in
    "$lock")     loginctl lock-session ;;
    "$reload")
        hyprctl reload >/dev/null
        errs=$(hyprctl configerrors 2>/dev/null | sed '/^$/d')
        if [[ -n $errs ]]; then notify-send -a hyprland -u critical "Hyprland reloaded with errors" "$errs"
        else notify-send -a hyprland "Hyprland reloaded"; fi ;;
    "$suspend")  systemctl suspend ;;
    "$logout")   hyprshutdown || hyprctl dispatch 'hl.dsp.exit()' ;;
    "$reboot")   systemctl reboot ;;
    "$shutdown") systemctl poweroff ;;
esac
