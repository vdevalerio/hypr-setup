#!/usr/bin/env bash
# Brilho independente por monitor: tela do notebook (brightnessctl) e monitores externos (DDC/CI, ddcutil).
#
#   brightness.sh up|down [alvo] [passo]   alvo: focused (padrão) | cursor | <monitor, ex. HDMI-A-2>
#   brightness.sh set <0-100> [alvo]
#   brightness.sh get [alvo]
#   brightness.sh list                     "monitor<TAB>nome<TAB>brilho" de cada monitor
#
# Teclas de brilho = monitor em foco; roda do mouse na bateria da barra = monitor da barra (sob o cursor).
# Externos precisam de DDC/CI ligado no menu do próprio monitor. ddcutil é lento: o valor fica em
# cache e é aplicado em segundo plano (rolagens rápidas viram uma única mudança).

STEP=5
CACHE="${XDG_RUNTIME_DIR:-/tmp}/brightness"
NOTIFY_ID="$CACHE/notify-id"
mkdir -p "$CACHE"

internal() { [[ $1 == eDP* || $1 == LVDS* || $1 == DSI* ]]; }

target() {
    case "${1:-focused}" in
        focused) hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' ;;
        cursor)
            hyprctl monitors -j | jq -r --argjson c "$(hyprctl cursorpos -j)" '
                .[] | (if (.transform % 2) == 1 then [.height, .width] else [.width, .height] end) as $s
                | select($c.x >= .x and $c.x < .x + $s[0] / .scale and $c.y >= .y and $c.y < .y + $s[1] / .scale)
                | .name' | head -1 ;;
        *) echo "$1" ;;
    esac
}

label() { # nome amigável: "Laptop" ou o modelo do monitor
    if internal "$1"; then echo Laptop; return; fi
    hyprctl monitors all -j | jq -r --arg n "$1" '.[] | select(.name == $n) | "\(.make) \(.model)" | sub("^Dell Inc\\. "; "")'
}

# Barramento I2C do monitor (ddcutil detect é lento: guardado em cache)
bus() {
    local f="$CACHE/bus-$1"
    if [ ! -s "$f" ]; then
        command -v ddcutil >/dev/null || return 1
        ddcutil detect --terse 2>/dev/null | awk -v want="$1" '
            /I2C bus:/       { split($NF, a, "-"); b = a[length(a)] }
            /DRM connector:/ { c = $NF; sub(/^card[0-9]+-/, "", c); if (c == want) { print b; exit } }' > "$f"
    fi
    [ -s "$f" ] && cat "$f"
}

get() {
    local m=$1 b
    if internal "$m"; then brightnessctl -e4 -m 2>/dev/null | cut -d, -f4 | tr -d '%'; return; fi
    [ -s "$CACHE/val-$m" ] && { cat "$CACHE/val-$m"; return; }
    b=$(bus "$m") || { echo "?"; return 1; }
    ddcutil --bus "$b" getvcp 10 --terse 2>/dev/null | awk '{ print $4 }' | tee "$CACHE/val-$m"
}

# Aplica o valor desejado no monitor externo; um worker por monitor, sempre com o último valor
ddc_apply() {
    local m=$1 b want done_v=""
    b=$(bus "$m") || return 1
    exec 8>"$CACHE/lock-$m"
    flock -n 8 || return 0
    while want=$(cat "$CACHE/val-$m" 2>/dev/null) && [ "$want" != "$done_v" ]; do
        ddcutil --bus "$b" --noverify setvcp 10 "$want" >/dev/null 2>&1
        done_v=$want
    done
}

osd() {
    local id args=(-a brightness -t 1200 -p)
    id=$(cat "$NOTIFY_ID" 2>/dev/null)
    [ -n "$id" ] && args+=(-r "$id")
    notify-send "${args[@]}" -h "int:value:$2" "󰃠  $(label "$1")" "$2%" > "$NOTIFY_ID" 2>/dev/null
}

set_value() { # set_value <monitor> <0-100>
    local m=$1 v=$2
    (( v < 1 )) && v=1; (( v > 100 )) && v=100
    if internal "$m"; then
        brightnessctl -e4 -n2 set "$v%" >/dev/null
    else
        bus "$m" >/dev/null || {
            notify-send -a brightness -u critical "Brightness: $(label "$m")" \
                "No DDC/CI on this monitor. Install ddcutil and enable DDC/CI in the monitor menu (see README)."
            return 1; }
        echo "$v" > "$CACHE/val-$m"
        ( ddc_apply "$m" & ) 8>&-
    fi
    osd "$m" "$v"
}

step() { # step <+|-> <alvo> [passo]
    local m cur
    m=$(target "$2"); [ -n "$m" ] || return 1
    cur=$(get "$m") || return 1
    [[ $cur =~ ^[0-9]+$ ]] || return 1
    set_value "$m" $(( cur $1 ${3:-$STEP} ))
}

case "${1:-}" in
    up)   step + "${2:-focused}" "${3:-}" ;;
    down) step - "${2:-focused}" "${3:-}" ;;
    set)  m=$(target "${3:-focused}"); set_value "$m" "${2:?valor}" ;;
    get)  get "$(target "${2:-focused}")" ;;
    list) for m in $(hyprctl monitors -j | jq -r '.[].name'); do
              printf '%s\t%s\t%s\n' "$m" "$(label "$m")" "$(get "$m" 2>/dev/null || echo "?")"
          done ;;
    *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
