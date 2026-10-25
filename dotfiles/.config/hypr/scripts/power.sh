#!/usr/bin/env bash
# Tomada × bateria (iniciado no login). Ao tirar da tomada: tela do notebook a 60 Hz (monitors.lua) e
# perfil de energia power-saver, guardando o perfil que estava em uso; ao voltar: 165 Hz e o perfil
# guardado. Na tomada, o perfil continua sendo o que você escolher na central de controle.
SIG=${HYPRLAND_INSTANCE_SIGNATURE:?rode dentro do Hyprland}
BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[ -n "$BAT" ] || exit 0                                   # PC sem bateria
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/power-$SIG.lock"
flock -n 9 || exit 0
alive() { [ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/$SIG/.socket.sock" ]; }
SAVED=~/.cache/power-profile-ac                           # perfil da tomada, restaurado ao voltar

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
    hyprctl reload >/dev/null                             # monitors.lua escolhe o modo pelo estado
    [ "${2:-}" = quiet ] || notify-send -a power -u low -i "$([ "$1" = battery ] && echo battery || echo ac-adapter)" \
        "$([ "$1" = battery ] && echo "On battery" || echo "Plugged in")" "$msg"
}

cur=$(state)
[ "$cur" = battery ] && apply battery quiet               # ligou já na bateria
while alive; do
    sleep 5
    new=$(state)
    [ "$new" = "$cur" ] && continue
    sleep 2; new=$(state)                                 # ignora oscilação ao encaixar o cabo
    [ "$new" = "$cur" ] && continue
    cur=$new; apply "$cur"
done
