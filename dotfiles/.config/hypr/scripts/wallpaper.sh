#!/usr/bin/env bash
# Wallpaper: images and animated GIFs (awww), videos (mpvpaper),
# and the system color theme: automatic (from the wallpaper) or a fixed theme (~/.config/hypr/themes).
#
#   wallpaper.sh set <file>             applies the wallpaper and recolors the system
#   wallpaper.sh pick                   visual picker (rofi)
#   wallpaper.sh random                 random wallpaper from the folder
#   wallpaper.sh restore                at login: reapplies the last wallpaper
#   wallpaper.sh theme auto|<tema>|toggle  color theme: auto (from the wallpaper), a fixed theme
#                                         (theme.py list) or toggles between auto and the last fixed one
#
# Wallpapers live in ~/Pictures/Wallpapers (png, jpg, webp, gif, mp4, webm, mkv, mov).

WALLDIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Wallpapers"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CURRENT="$STATE/current"
LOCKBG="$STATE/lock.png"   # lock screen background (hyprlock.conf)
MODE_FILE="$STATE/theme-mode"      # "auto" or the id of a fixed theme
LAST_FIXED="$STATE/theme-last"     # last fixed theme used (for "toggle")
THEME=~/.config/hypr/themes/theme.py
DEFAULT="$WALLDIR/aurora.mp4"
# Current choice also stored in look.conf (ships with hypr-setup): on a new machine
# restore uses the same wallpaper and the same color mode.
LOOK=~/.config/hypr/look.conf
mkdir -p "$STATE/thumbs"

kind() {
    case "$(file -b -L --mime-type "$1")" in
        image/gif) echo gif ;;
        video/*)   echo video ;;
        image/*)   echo image ;;
        *)         echo unknown ;;
    esac
}

# First frame (or the frame at 1s for videos) as PNG
frame() {
    local src=$1 out=$2 scale=${3:-}
    local vf=${scale:+-vf scale=$scale:-1}
    ffmpeg -nostdin -loglevel error -y -ss 1 -i "$src" -frames:v 1 $vf "$out" 2>/dev/null && [ -s "$out" ] ||
        ffmpeg -nostdin -loglevel error -y -i "$src" -frames:v 1 $vf "$out"
}

thumb() {
    local f=$1 t
    t="$STATE/thumbs/$(printf '%s%s' "$f" "$(stat -c %Y "$f")" | md5sum | cut -c1-16).png"
    [ -f "$t" ] || frame "$f" "$t" 320
    echo "$t"
}

start_awww() {
    pgrep -x awww-daemon >/dev/null || setsid -f awww-daemon </dev/null >/dev/null 2>&1 9>&-
    for _ in $(seq 50); do
        awww query >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    return 1
}

show() {
    local f=$1
    case "$(kind "$f")" in
        video)
            pkill -x mpvpaper || true
            # One mpvpaper per monitor. -p pauses the video only on the monitor where it is covered
            # (e.g. a fullscreen window). Don't use "-a FULL": it pauses all monitors
            # if there is any fullscreen window, even on a hidden workspace.
            # 9>&- and setsid: mpvpaper inherits neither the script's lock nor the terminal
            local out
            for out in $(hyprctl monitors -j | jq -r '.[].name'); do
                # igpu.sh + vaapi: decodes on the integrated GPU; on the NVIDIA it would never power off
                setsid -f ~/.config/hypr/scripts/igpu.sh mpvpaper -f -p \
                    -o "no-audio --loop-file=inf --hwdec=vaapi,auto-safe --panscan=1.0 --really-quiet" \
                    "$out" "$f" </dev/null >/dev/null 2>&1 9>&-
            done
            sleep 0.8 # let the video show up before removing the previous image (no flicker)
            pkill -x awww-daemon || true
            ;;
        image|gif)
            start_awww || { notify-send -u critical "Wallpaper" "awww-daemon did not start"; return 1; }
            awww img "$f" --transition-type grow --transition-pos 0.5,0.5 \
                --transition-duration 1.2 --transition-fps 120
            pkill -x mpvpaper || true
            ;;
        *)
            notify-send -u critical "Wallpaper" "Unsupported file: $(basename "$f")"
            return 1 ;;
    esac
}

# Wallpaper frame (image, GIF or video) for the lock screen background
lock_bg() { frame "$1" "$LOCKBG.tmp.png" 2560 && mv -f "$LOCKBG.tmp.png" "$LOCKBG"; }

remember() { # remember <key> <value>  (writes to look.conf)
    [ -f "$LOOK" ] || return 0
    if grep -q "^$1=" "$LOOK"; then sed -i "s|^$1=.*|$1=$2|" "$LOOK"; else echo "$1=$2" >> "$LOOK"; fi
}
remembered() { sed -n "s/^$1=//p" "$LOOK" 2>/dev/null | tail -1; }

reload_apps() {
    hyprctl reload >/dev/null
    pkill -SIGUSR2 -x waybar        # reload the bar style
    swaync-client -rs >/dev/null 2>&1
    pkill -SIGUSR1 -x kitty         # reload colors of open terminals
    ~/.config/hypr/scripts/sddm-sync.sh 9>&- &  # login screen: new background and colors (without inheriting the lock)
    fcitx5-remote -r 2>/dev/null    # candidate window theme (Japanese)
}

# Current theme: "auto" or a fixed theme id ("fixed" = old versions = Catppuccin)
mode() {
    local m; m=$(cat "$MODE_FILE" 2>/dev/null)
    case "$m" in ""|auto) echo auto ;; fixed) echo catppuccin-mocha ;; *) echo "$m" ;; esac
}

recolor() {
    local f=$1 src=$1 m; m=$(mode)
    if [ "$m" = auto ]; then
        if [ "$(kind "$f")" != image ]; then
            src="$STATE/frame.png"
            frame "$f" "$src" || return 1
        fi
        python3 "$THEME" auto "$src" || return 1
    else
        python3 "$THEME" set "$m" || return 1
    fi
    reload_apps
}

set_wall() {
    local f
    f=$(realpath "$1") || return 1
    show "$f" || return 1
    echo "$f" > "$CURRENT"
    remember wallpaper "$(basename "$f")"
    lock_bg "$f"
    recolor "$f"
    notify-send -a wallpaper -i "$(thumb "$f")" "Wallpaper" "$(basename "$f")"
}

list_walls() {
    find -L "$WALLDIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \
           -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) | sort
}

pick() {
    pkill -x rofi && exit 0
    local walls sel
    mapfile -t walls < <(list_walls)
    if [ ${#walls[@]} -eq 0 ]; then
        notify-send "Wallpaper" "Put images, GIFs or videos in $WALLDIR"
        exit 0
    fi
    local mode; mode=$(python3 "$THEME" name "$(mode)")
    sel=$(for f in "${walls[@]}"; do
            printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$(thumb "$f")"
          done | rofi -dmenu -i -p "Wallpaper" -show-icons -no-custom \
            -mesg "Theme: $mode   ·   Alt+T: automatic ↔ last fixed theme" \
            -kb-custom-1 "Alt+t" \
            -theme-str 'window {width: 1000px;}
                        listview {columns: 4; lines: 2; spacing: 10px;}
                        element {orientation: vertical; padding: 10px; spacing: 8px;}
                        element-icon {size: 190px;}
                        element-text {horizontal-align: 0.5;}')
    local status=$?
    if [ $status -eq 10 ]; then lock; theme toggle; flock -u 9; exec "$0" pick; fi
    [ -n "$sel" ] && { lock; set_wall "$WALLDIR/$sel"; }
}

theme() {
    local new
    case "${1:-toggle}" in
        toggle) if [ "$(mode)" = auto ]; then new=$(cat "$LAST_FIXED" 2>/dev/null || echo catppuccin-mocha)
                else new=auto; fi ;;
        fixed)  new=catppuccin-mocha ;;
        *)      new=$1 ;;
    esac
    if [ "$new" != auto ] && ! python3 "$THEME" name "$new" >/dev/null 2>&1; then
        notify-send -a wallpaper -u critical "Theme" "Unknown theme: $new"; return 1
    fi
    echo "$new" > "$MODE_FILE"
    [ "$new" != auto ] && echo "$new" > "$LAST_FIXED"
    remember colors "$new"
    recolor "$(cat "$CURRENT" 2>/dev/null || echo "$DEFAULT")"
    notify-send -a wallpaper "Theme" "$(python3 "$THEME" name "$new")"
}

# Prevents two switches at the same time (e.g. clicking several times)
exec 9>"$STATE/lock"
lock() { flock -n 9 || exit 0; }

case "${1:-}" in
    set)     lock; set_wall "$2" ;;
    pick)    pick ;;
    random)  lock; mapfile -t w < <(list_walls); [ ${#w[@]} -gt 0 ] && set_wall "${w[RANDOM % ${#w[@]}]}" ;;
    theme)   lock; theme "${2:-toggle}" ;;
    restore)
        lock
        f=$(cat "$CURRENT" 2>/dev/null)
        if [ -f "$f" ]; then show "$f"; [ -s "$LOCKBG" ] || lock_bg "$f"
        else
            # new machine: color mode and wallpaper remembered in look.conf, otherwise the default
            [ -f "$MODE_FILE" ] || [ -z "$(remembered colors)" ] || remembered colors > "$MODE_FILE"
            f="$WALLDIR/$(remembered wallpaper)"
            [ -f "$f" ] || f=$DEFAULT
            [ -f "$f" ] || f=$(list_walls | head -1)
            [ -n "$f" ] && set_wall "$f"
        fi ;;
    *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
