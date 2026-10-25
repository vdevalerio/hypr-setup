#!/usr/bin/env bash
# Battery warnings (started at login): 15% warning, 8% critical, 4% auto-suspend in 30 s
# (if still on battery). Warns once per level; warns again after charging.
SIG=${HYPRLAND_INSTANCE_SIGNATURE:?run inside Hyprland}
BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[ -n "$BAT" ] || exit 0                                   # PC without a battery
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/battery-watch-$SIG.lock"
flock -n 9 || exit 0
alive() { [ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/$SIG/.socket.sock" ]; }

level=100   # lowest level already warned about
while alive; do
    cap=$(cat "$BAT/capacity"); status=$(cat "$BAT/status")
    if [ "$status" = Discharging ]; then
        if (( cap <= 4 && level > 4 )); then
            level=4
            notify-send -a battery -u critical -i battery-empty "Battery ${cap}%" "Suspending in 30 seconds — plug in the charger"
            sleep 30
            [ "$(cat "$BAT/status")" = Discharging ] && systemctl suspend
        elif (( cap <= 8 && level > 8 )); then
            level=8
            notify-send -a battery -u critical -i battery-caution "Battery ${cap}%" "Plug in the charger now"
        elif (( cap <= 15 && level > 15 )); then
            level=15
            notify-send -a battery -i battery-low "Battery ${cap}%" "Battery is getting low"
        fi
    else
        level=100
    fi
    sleep 60
done
