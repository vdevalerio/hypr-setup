#!/usr/bin/env bash
# Tampa do notebook com monitor externo ("clamshell"). Chamado pelo Hyprland (binds.lua):
#   lid.sh close   tampa fechada: com outro monitor, desliga só a tela do notebook
#                  (sem monitor externo quem age é o systemd: suspende)
#   lid.sh open    tampa aberta: liga a tela do notebook de novo
#   lid.sh check   no login e ao desconectar monitor, se a tampa estiver fechada
# Não grava nada no monitors.conf: é só enquanto a tampa estiver fechada.
internal=$(hyprctl monitors all -j | jq -r '[.[] | select(.name | test("^(eDP|LVDS|DSI)"))][0].name // empty')
[ -n "$internal" ] || exit 0
desc=$(hyprctl monitors all -j | jq -r --arg n "$internal" '.[] | select(.name == $n) | .description' | sed 's/[[:space:]]*$//')
others() { hyprctl monitors -j | jq --arg n "$internal" '[.[] | select(.name != $n)] | length'; }
lid_closed() { grep -qs closed /proc/acpi/button/lid/*/state; }

close() {
    (( $(others) > 0 )) || return 0
    # pela descrição: tem prioridade sobre as regras por nome (os ajustes de Displays são por descrição)
    hyprctl eval "hl.monitor({ output = 'desc:$desc', disabled = true })" >/dev/null
}

open() {
    # Recarregar a config religa a tela com os ajustes de Displays (uma regra nova por cima da
    # de "desligado" não basta para o Hyprland reativar o monitor). Os workspaces voltam sozinhos.
    hyprctl reload >/dev/null
    sleep 0.8
    hyprctl eval 'require("workspaces").setup()' >/dev/null
}

case "${1:-}" in
    close) close ;;
    open)  open ;;
    check)
        # Só com a tampa fechada (abrir a tampa já chama "open" pelo evento do Hyprland):
        # com monitor externo, mantém a tela do notebook desligada; sem nenhum, religa.
        lid_closed || exit 0
        if (( $(others) > 0 )); then close
        elif [ "$(hyprctl monitors -j | jq --arg n "$internal" 'any(.[]; .name == $n)')" = false ]; then open
        fi ;;
    *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
