#!/usr/bin/env bash
# AC vs. battery (started at login). When unplugged: laptop screen at 60 Hz (monitors.lua) and
# power-saver power profile, saving the profile that was in use; when plugged back in: 165 Hz and the saved
# profile. On AC, the profile remains whatever you pick in the control center.
SIG=${HYPRLAND_INSTANCE_SIGNATURE:?run inside Hyprland}
BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[ -n "$BAT" ] || exit 0                                   # PC without a battery
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/power-$SIG.lock"
flock -n 9 || exit 0
alive() { [ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/$SIG/.socket.sock" ]; }
SAVED=~/.cache/power-profile-ac                           # AC profile, restored when plugged back in

state() { [ "$(cat "$BAT/status")" = Discharging ] && echo battery || echo ac; }

apply() {
    if [ "$1" = battery ]; then
        powerprofilesctl get > "$SAVED" 2>/dev/null
        powerprofilesctl set power-saver 2>/dev/null
        msg="Screen at 60 Hz · power saver"
    else
        local p; p=$(cat "$SAVED" 2>/dev/null); powerprofilesctl set "${p:-balanced}" 2>/dev/null
        msg="Screen at full refresh rate · ${p:-balanced}"
    fi
    hyprctl reload >/dev/null                             # monitors.lua picks the mode from the state
    [ "${2:-}" = quiet ] || notify-send -a power -u low -i "$([ "$1" = battery ] && echo battery || echo ac-adapter)" \
        "$([ "$1" = battery ] && echo "On battery" || echo "Plugged in")" "$msg"
}

cur=$(state)
[ "$cur" = battery ] && apply battery quiet               # booted already on battery
while alive; do
    sleep 5
    new=$(state)
    [ "$new" = "$cur" ] && continue
    sleep 2; new=$(state)                                 # ignore flapping while the cable is being plugged in
    [ "$new" = "$cur" ] && continue
    cur=$new; apply "$cur"
done
