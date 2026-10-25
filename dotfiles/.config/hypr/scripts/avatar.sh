#!/usr/bin/env bash
# Profile photo (shown on the lock screen). Stores a square crop in ~/.face.
#
#   avatar.sh pick           choose from the images in Pictures, Downloads and Desktop (rofi)
#   avatar.sh browse         choose any file with yazi (Enter selects)
#   avatar.sh set <file>     use this image
#   avatar.sh remove         go back to the icon
#
# Portrait photos are cropped closer to the top (where the face usually is).

FACE=~/.face
THUMBS=~/.cache/avatar/thumbs
mkdir -p "$THUMBS"

set_face() {
    local src=$1 tmp w h side x y
    [ -f "$src" ] || { notify-send -a avatar "Profile photo" "File not found: $src"; return 1; }
    tmp=$(mktemp --suffix=.png)
    # [0] = first frame (GIF), -auto-orient = phone photo in the right orientation
    if ! magick "$src[0]" -auto-orient -background '#11111b' -flatten "$tmp" 2>/dev/null; then
        rm -f "$tmp"
        notify-send -a avatar -u critical "Profile photo" "Not an image: $(basename "$src")"
        return 1
    fi
    read -r w h < <(magick identify -format '%w %h' "$tmp")
    if (( w >= h )); then side=$h; x=$(( (w - h) / 2 )); y=0
    else                  side=$w; x=0; y=$(( (h - w) / 4 )); fi
    magick "$tmp" -crop "${side}x${side}+${x}+${y}" +repage -resize 512x512 -alpha off -strip "png:$FACE.tmp" &&
        mv -f "$FACE.tmp" "$FACE"
    rm -f "$tmp"
    cp -f "$FACE" ~/.face.icon   # same name SDDM/GNOME look for
    ~/.config/hypr/scripts/sddm-sync.sh   # login screen
    notify-send -a avatar -i "$FACE" "Profile photo" "Updated · shows on the lock and login screens"
}

thumb() {
    local f=$1 t
    t="$THUMBS/$(printf '%s%s' "$f" "$(stat -c %Y "$f")" | md5sum | cut -c1-16).png"
    [ -f "$t" ] || magick "$f[0]" -auto-orient -thumbnail 256x256^ -gravity center -extent 256x256 "$t" 2>/dev/null
    echo "$t"
}

pick() {
    pkill -x rofi && exit 0
    local files=() f sel
    mapfile -t files < <(
        find -L ~/Pictures ~/Downloads ~/Desktop -maxdepth 3 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) \
            -not -path '*/Screenshots/*' -printf '%T@\t%p\n' 2>/dev/null | sort -rn | cut -f2 | head -60)
    sel=$( {
        printf '%s\0icon\x1f%s\n' "󰉋  Browse…" "folder-pictures"
        [ -f "$FACE" ] && printf '%s\0icon\x1f%s\n' "󰆴  Remove photo" "$FACE"
        for f in "${files[@]}"; do printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$(thumb "$f")"; done
    } | rofi -dmenu -i -p "Profile photo" -show-icons -no-custom -format i \
        -mesg "Newest images first · the photo is cropped to a circle" \
        -theme-str 'window {width: 900px;}
                    listview {columns: 5; lines: 2; spacing: 10px; flow: horizontal; fixed-columns: true;}
                    element {orientation: vertical; padding: 10px; spacing: 8px;}
                    element-icon {size: 130px;}
                    element-text {horizontal-align: 0.5;}') || exit 0
    [ -n "$sel" ] || exit 0
    local extra=1; [ -f "$FACE" ] && extra=2
    if   (( sel == 0 )); then browse
    elif (( sel == 1 && extra == 2 )); then remove
    else set_face "${files[sel - extra]}"; fi
}

browse() {
    local out; out=$(mktemp)
    kitty --class yazi -e yazi --chooser-file="$out" ~/Pictures
    [ -s "$out" ] && set_face "$(head -1 "$out")"
    rm -f "$out"
}

remove() {
    rm -f "$FACE" ~/.face.icon
    ~/.config/hypr/scripts/sddm-sync.sh
    notify-send -a avatar "Profile photo" "Removed · the lock screen shows the icon again"
}

case "${1:-}" in
    pick)   pick ;;
    browse) browse ;;
    set)    set_face "${2:?file}" ;;
    remove) remove ;;
    *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
