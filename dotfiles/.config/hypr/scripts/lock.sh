#!/usr/bin/env bash
# Bloqueia a tela (lock_cmd do hypridle; SUPER+Esc e o menu de energia chegam aqui pelo
# `loginctl lock-session`). Usa a tela do Quickshell (~/.config/quickshell/lock.qml, com o wallpaper
# animado); se ela não abrir ou cair, o hyprlock assume — a sessão continua bloqueada enquanto isso
# (misc.allow_session_lock_restore no hyprland.lua).
pidof hyprlock >/dev/null && exit 0
pgrep -f "quickshell/[l]ock.qml" >/dev/null && exit 0
if command -v qs >/dev/null && [ -f ~/.config/quickshell/lock.qml ]; then
    qs -p ~/.config/quickshell/lock.qml && exit 0
fi
exec hyprlock
