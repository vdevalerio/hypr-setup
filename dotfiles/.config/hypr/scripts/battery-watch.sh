#!/usr/bin/env bash
# Avisos de bateria (iniciado no login): 15% aviso, 8% crítico, 4% suspende sozinho em 30 s
# (se continuar na bateria). Só avisa uma vez por nível; volta a avisar depois de carregar.
SIG=${HYPRLAND_INSTANCE_SIGNATURE:?rode dentro do Hyprland}
BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[ -n "$BAT" ] || exit 0                                   # PC sem bateria
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/battery-watch-$SIG.lock"
flock -n 9 || exit 0
alive() { [ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/$SIG/.socket.sock" ]; }

level=100   # menor nível já avisado
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
