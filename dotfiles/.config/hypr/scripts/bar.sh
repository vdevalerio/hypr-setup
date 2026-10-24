#!/usr/bin/env bash
# Inicia a Waybar e a reinicia se ela travar (crash). Fechar de propósito (pkill waybar) encerra.
# Preso à sessão do Hyprland que o iniciou: quando ela acaba (logout), o bar.sh sai junto, e a
# trava é por sessão, para uma sessão nova nunca ficar sem barra por causa de uma antiga.
SIG=${HYPRLAND_INSTANCE_SIGNATURE:?rode dentro do Hyprland}
alive() { [ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/$SIG/.socket.sock" ]; }

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/bar-$SIG.lock"
flock -n 9 || exit 0                       # já tem um bar.sh nesta sessão
while alive; do
    start=$(date +%s)
    waybar 9>&-
    code=$?
    [ "$code" -eq 0 ] && exit 0            # saiu normalmente (pkill/SIGTERM)
    alive || exit 0                        # a sessão acabou: não reabre
    notify-send -a waybar -u low "Bar" "Waybar crashed (exit $code) and was restarted"
    (( $(date +%s) - start < 5 )) && sleep 3   # travando em seguida: espera um pouco
done
