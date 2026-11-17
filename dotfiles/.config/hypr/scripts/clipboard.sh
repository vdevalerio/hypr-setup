#!/usr/bin/env bash
# Clipboard history (SUPER + V, or the clipboard button in the bar)
# Enter copies the item (then paste with Ctrl+V); Shift+Delete deletes it; Alt+Delete clears everything
#   clipboard.sh           picker (rofi)
#   clipboard.sh status    JSON for Waybar's custom/clipboard module (count + the latest items as tooltip)
if [ "${1:-}" = status ]; then
    n=$(cliphist list 2>/dev/null | wc -l)
    tip=$(cliphist list 2>/dev/null | head -6 | cut -f2- | tr -d '\0' | cut -c1-60 | sed 's/^\[\[ binary data \(.*\) \]\]$/[image \1]/; s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    jq -nc --arg n "$n" --arg tip "$(printf 'Clipboard history (%s)\n\n%s\n\nClick: open · SUPER + V' "$n" "$tip")" \
        '{text: $n, tooltip: $tip, class: (if $n == "0" then "empty" else "" end)}'
    exit 0
fi
pkill -x rofi && exit 0
tmp=$(mktemp)
cliphist list | rofi -dmenu -i -p "Clipboard" -display-columns 2 \
    -kb-delete-entry "" -kb-custom-1 "Shift+Delete" -kb-custom-2 "Alt+Delete" \
    -mesg "Enter: copy · Shift+Del: delete · Alt+Del: clear all" > "$tmp"
status=$?
sel=$(cat "$tmp"); rm -f "$tmp"
[ "$status" = 11 ] && { cliphist wipe; notify-send -a clipboard "Clipboard history cleared"; exit 0; }
[ -z "$sel" ] && exit 0
case $status in
    0)  printf '%s' "$sel" | cliphist decode | wl-copy ;;
    10) printf '%s' "$sel" | cliphist delete; exec "$0" ;;
esac
