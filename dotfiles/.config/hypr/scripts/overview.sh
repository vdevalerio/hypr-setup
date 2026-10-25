#!/usr/bin/env bash
# Workspace overview (SUPER + Tab): toggles the Quickshell screen (~/.config/quickshell/overview.qml).
#   overview.sh [toggle|open|close]   (default: toggle)
#   overview.sh start                 starts the resident process (autostart in hyprland.lua)
# If the process isn't running (crashed, or first time), start it and open right away.
QML=$HOME/.config/quickshell/overview.qml
cmd=${1:-toggle}

running() { qs -p "$QML" ipc show >/dev/null 2>&1; }

start() {
    running && return 0
    # On the integrated GPU: the process stays open all the time and must not keep the NVIDIA awake
    setsid -f ~/.config/hypr/scripts/igpu.sh qs -p "$QML" >/dev/null 2>&1
    for _ in {1..30}; do running && return 0; sleep 0.1; done
    return 1
}

case $cmd in
start) start ;;
toggle|open|close)
    start || { notify-send -a overview "Overview" "Quickshell did not start (see: qs -p $QML)"; exit 1; }
    qs -p "$QML" ipc call overview "$cmd" ;;
*) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
