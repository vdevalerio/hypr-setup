#!/usr/bin/env bash
# Clipboard history (SUPER + V)
# Enter pastes the item; Shift+Delete deletes the selected item
pkill -x rofi && exit 0
tmp=$(mktemp)
cliphist list | rofi -dmenu -i -p "Clipboard" -display-columns 2 \
    -kb-delete-entry "" -kb-custom-1 "Shift+Delete" -mesg "Enter: copy · Shift+Del: delete" > "$tmp"
status=$?
sel=$(cat "$tmp"); rm -f "$tmp"
[ -z "$sel" ] && exit 0
case $status in
    0)  printf '%s' "$sel" | cliphist decode | wl-copy ;;
    10) printf '%s' "$sel" | cliphist delete; exec "$0" ;;
esac
