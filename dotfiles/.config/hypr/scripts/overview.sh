#!/usr/bin/env bash
# Visão geral dos workspaces (SUPER + Tab): alterna a tela do Quickshell (~/.config/quickshell/overview.qml).
#   overview.sh [toggle|open|close]   (padrão: toggle)
#   overview.sh start                 inicia o processo residente (autostart no hyprland.lua)
# Se o processo não estiver rodando (caiu, ou primeira vez), inicia e já abre.
QML=$HOME/.config/quickshell/overview.qml
cmd=${1:-toggle}

running() { qs -p "$QML" ipc show >/dev/null 2>&1; }

start() {
    running && return 0
    # Na GPU integrada: o processo fica aberto o tempo todo e não pode prender a NVIDIA
    setsid -f ~/.config/hypr/scripts/igpu.sh qs -p "$QML" >/dev/null 2>&1
    for _ in {1..30}; do running && return 0; sleep 0.1; done
    return 1
}

case $cmd in
start) start ;;
toggle|open|close)
    start || { notify-send -a overview "Overview" "Quickshell não iniciou (veja: qs -p $QML)"; exit 1; }
    qs -p "$QML" ipc call overview "$cmd" ;;
*) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
