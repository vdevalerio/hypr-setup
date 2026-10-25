#!/usr/bin/env bash
# Locks the screen (hypridle's lock_cmd; SUPER+Esc and the power menu get here via
# `loginctl lock-session`). Uses the Quickshell screen (~/.config/quickshell/lock.qml, with the animated
# wallpaper); if it fails to open or crashes, hyprlock takes over — the session stays locked in the
# meantime (misc.allow_session_lock_restore in hyprland.lua).
pidof hyprlock >/dev/null && exit 0
pgrep -f "quickshell/[l]ock.qml" >/dev/null && exit 0
if command -v qs >/dev/null && [ -f ~/.config/quickshell/lock.qml ]; then
    qs -p ~/.config/quickshell/lock.qml && exit 0
fi
exec hyprlock
