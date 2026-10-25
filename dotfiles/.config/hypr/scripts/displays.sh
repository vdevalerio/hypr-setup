#!/usr/bin/env bash
# Monitor configuration (control center → Displays). Writes to ~/.config/hypr/monitors.conf
# (one section per monitor, by description) and applies it immediately via monitors.lua.
#
#   displays.sh place <monitor> left|right|above|below <other>   position relative to another monitor
#   displays.sh set   <monitor> mode|scale|transform|mirror <value>
#   displays.sh unset <monitor> <key>                          back to default (e.g. unset HDMI-A-2 mirror)
#   displays.sh enable|disable <monitor>
#   displays.sh reset <monitor> | reset-all                      everything automatic again
#   displays.sh info  <monitor>                                  one-line summary

CONF=~/.config/hypr/monitors.conf

json()  { hyprctl monitors all -j; }
desc()  { json | jq -r --arg n "$1" '.[] | select(.name == $n) | .description' | sed 's/[[:space:]]*$//'; }
label() { [[ $1 == eDP* ]] && { echo Laptop; return; }
          json | jq -r --arg n "$1" '.[] | select(.name == $n) | .model'; }

ini_set() { # ini_set <section> <key> <value>  (empty value = removes the key)
    [ -f "$CONF" ] || printf '# Per-monitor settings (control center → Displays, scripts/displays.sh)\n' > "$CONF"
    awk -v sec="[$1]" -v key="$2" -v val="$3" '
        function emit() { if (val != "") print key "=" val; done = 1 }
        $0 == sec { insec = 1; found = 1; print; next }
        /^\[/ && insec { if (!done) emit(); insec = 0 }
        insec && index($0, key "=") == 1 { if (!done) emit(); next }
        { print }
        END { if (insec && !done) emit(); else if (!found && val != "") { print ""; print sec; print key "=" val } }
    ' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
}

ini_drop() { # removes the whole section
    [ -f "$CONF" ] || return 0
    awk -v sec="[$1]" '$0 == sec { skip = 1; next } /^\[/ { skip = 0 } !skip' "$CONF" > "$CONF.tmp" &&
        mv "$CONF.tmp" "$CONF"
}

apply() {
    hyprctl eval 'require("monitors").apply()' >/dev/null
    sleep 0.6
    hyprctl eval 'require("workspaces").setup()' >/dev/null
    pkill -RTMIN+8 -x waybar 2>/dev/null
}

need() { [ -n "$(desc "$1")" ] || { echo "unknown monitor: $1" >&2; exit 1; }; }

# Logical size (pixels / scale, swapping width and height if rotated)
geom() { json | jq -r --arg n "$1" '.[] | select(.name == $n)
          | (if (.transform % 2) == 1 then [.height, .width] else [.width, .height] end) as $s
          | "\(.x) \(.y) \($s[0] / .scale | floor) \($s[1] / .scale | floor)"'; }

place() {
    local m=$1 side=$2 ref=$3 n x y w h minx miny
    need "$m"; need "$ref"
    # Current position and logical size of all enabled monitors (that aren't mirroring another)
    declare -A X Y W H
    while read -r n x y w h; do X[$n]=$x; Y[$n]=$y; W[$n]=$w; H[$n]=$h; done < <(
        json | jq -r '.[] | select((.disabled | not) and .mirrorOf == "none")
            | (if (.transform % 2) == 1 then [.height, .width] else [.width, .height] end) as $s
            | "\(.name) \(.x) \(.y) \($s[0] / .scale | floor) \($s[1] / .scale | floor)"')
    [ -n "${W[$ref]:-}" ] || { notify-send -a displays "Displays" "$(label "$ref") is off or mirroring"; exit 1; }
    # monitor that was mirroring: use its own size
    [ -n "${W[$m]:-}" ] || read -r _ _ W[$m] H[$m] < <(geom "$m")
    case $side in
        left)  X[$m]=$(( X[$ref] - W[$m] )); Y[$m]=${Y[$ref]} ;;
        right) X[$m]=$(( X[$ref] + W[$ref] )); Y[$m]=${Y[$ref]} ;;
        above) X[$m]=${X[$ref]}; Y[$m]=$(( Y[$ref] - H[$m] )) ;;
        below) X[$m]=${X[$ref]}; Y[$m]=$(( Y[$ref] + H[$ref] )) ;;
        *) usage ;;
    esac
    # Pins the position of ALL of them (a monitor on "auto" would go to the right of the pinned ones) and
    # shifts everything so the leftmost/topmost corner ends up at 0,0
    minx=${X[$m]}; miny=${Y[$m]}
    for n in "${!X[@]}"; do (( X[$n] < minx )) && minx=${X[$n]}; (( Y[$n] < miny )) && miny=${Y[$n]}; done
    for n in "${!X[@]}"; do
        ini_set "$(desc "$n")" position "$(( X[$n] - minx ))x$(( Y[$n] - miny ))"
    done
    ini_set "$(desc "$m")" mirror ""
    apply
    notify-send -a displays "Displays" "$(label "$m") is now $side of $(label "$ref")"
}

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

case "${1:-}" in
    place)   place "${2:?}" "${3:?}" "${4:?}" ;;
    set)     need "${2:?}"; ini_set "$(desc "$2")" "${3:?}" "${4:?}"; apply ;;
    unset)   need "${2:?}"; ini_set "$(desc "$2")" "${3:?}" ""; apply ;;
    disable)
        need "${2:?}"
        [ "$(hyprctl monitors -j | jq length)" -gt 1 ] || { notify-send -a displays "Displays" "Can't turn off the only monitor"; exit 1; }
        ini_set "$(desc "$2")" disabled true; apply ;;
    enable)  need "${2:?}"; ini_set "$(desc "$2")" disabled ""; apply ;;
    reset)
        need "${2:?}"; ini_drop "$(desc "$2")"
        # without a section the old rule would stay in effect: explicitly go back to automatic
        hyprctl eval "hl.monitor({ output = 'desc:$(desc "$2")', mode = 'preferred', position = 'auto', scale = $(s=$(sed -n 's/^scale=//p' ~/.config/hypr/look.conf); [[ $s =~ ^[0-9.]+$ ]] && echo "$s" || echo '"auto"') })" >/dev/null
        apply ;;
    reset-all)
        for m in $(json | jq -r '.[].name'); do "$0" reset "$m"; done ;;
    info)
        json | jq -r --arg n "${2:?}" '.[] | select(.name == $n)
            | if .disabled then "off"
              elif .mirrorOf != "none" then "mirror of \(.mirrorOf)"
              else "\(.width)×\(.height)@\(.refreshRate | round) · ×\(.scale * 100 | round / 100) · \(.x),\(.y)" end' ;;
    *) usage ;;
esac
