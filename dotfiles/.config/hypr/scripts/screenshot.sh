#!/usr/bin/env bash
# Screenshots: region | screen | edit
dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$1" in
    screen)
        grim "$file" ;;
    edit)
        area=$(slurp -d -b 1e1e2e88 -c cba6f7ff -w 2) || exit 0
        grim -g "$area" - | satty --filename - --output-filename "$file" --early-exit
        exit 0 ;;
    *)
        area=$(slurp -d -b 1e1e2e88 -c cba6f7ff -w 2) || exit 0
        grim -g "$area" "$file" ;;
esac

wl-copy < "$file"
action=$(notify-send -i "$file" -A "open=Open" -A "edit=Edit" "Screenshot saved" "Copied to clipboard\n$(basename "$file")")
case "$action" in
    open) xdg-open "$file" ;;
    edit) satty --filename "$file" --output-filename "$file" ;;
esac
