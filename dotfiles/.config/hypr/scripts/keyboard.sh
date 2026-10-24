#!/usr/bin/env bash
# Idioma do teclado (fcitx5): português, inglês, russo e japonês.
# A lista e a ordem vêm de ~/.config/fcitx5/profile.
#
#   keyboard.sh next | prev        próximo / anterior (SUPER + CTRL + Espaço / + SHIFT)
#   keyboard.sh set <n|nome>       direto: 1..4 (SUPER + CTRL + 1..4) ou nome (keyboard-us, mozc...)
#   keyboard.sh pick               menu (rofi)
#   keyboard.sh status             JSON para o módulo custom/keyboard da Waybar

PROFILE=~/.config/fcitx5/profile
NOTIFY_ID="${XDG_RUNTIME_DIR:-/tmp}/keyboard-notify-id"

# nome do fcitx5 -> sigla, nome legível
short() { case $1 in keyboard-br*) echo PT ;; keyboard-us*) echo EN ;; keyboard-ru*) echo RU ;; mozc) echo JA ;; *) echo "${1#keyboard-}" | tr a-z A-Z ;; esac; }
label() { case $1 in keyboard-br*) echo "Português (ABNT2)" ;; keyboard-us*) echo English ;; keyboard-ru*) echo "Русский" ;; mozc) echo "日本語 (Mozc)" ;; *) echo "$1" ;; esac; }

ims() { awk -F= '/^\[Groups\/0\/Items\/[0-9]+\]/ { item = 1; next } /^\[/ { item = 0 } item && $1 == "Name" { print $2 }' "$PROFILE"; }
current() { fcitx5-remote -n 2>/dev/null; }

running() {
    if ! pgrep -x fcitx5 >/dev/null; then
        command -v fcitx5 >/dev/null || { notify-send -a keyboard "Keyboard" "fcitx5 is not installed (see hypr-setup README)"; exit 1; }
        setsid -f fcitx5 -d --replace >/dev/null 2>&1
        for _ in $(seq 30); do fcitx5-remote >/dev/null 2>&1 && break; sleep 0.1; done
    fi
}

osd() {
    local id args=(-a keyboard -t 1200 -p)
    id=$(cat "$NOTIFY_ID" 2>/dev/null)
    [ -n "$id" ] && args+=(-r "$id")
    notify-send "${args[@]}" "󰌌  $(short "$1")" "$(label "$1")" > "$NOTIFY_ID" 2>/dev/null
}

switch_to() {
    fcitx5-remote -s "$1"
    pkill -RTMIN+9 -x waybar 2>/dev/null
    osd "$1"
}

step() { # step +1 | -1
    local list cur i n
    mapfile -t list < <(ims)
    n=${#list[@]}; cur=$(current)
    for i in "${!list[@]}"; do [ "${list[i]}" = "$cur" ] && break; done
    [ "${list[i]}" = "$cur" ] || i=0
    switch_to "${list[$(( (i + $1 + n) % n ))]}"
}

pick() {
    pkill -x rofi && exit 0
    local list cur rows=() im idx
    mapfile -t list < <(ims); cur=$(current)
    for im in "${list[@]}"; do
        rows+=("$(printf '%s   %-20s <span alpha="55%%">%s</span>' "$(short "$im")" "$(label "$im")" "$([ "$im" = "$cur" ] && echo "● active")")")
    done
    idx=$(printf '%s\n' "${rows[@]}" | rofi -dmenu -i -markup-rows -no-custom -format i -p "Keyboard" \
        -theme-str "window {width: 420px;} listview {lines: ${#rows[@]};}") || exit 0
    [ -n "$idx" ] && switch_to "${list[idx]}"
}

status() {
    local cur
    pgrep -x fcitx5 >/dev/null || { echo '{"text": ""}'; exit 0; }
    cur=$(current)
    printf '{"text": "%s", "tooltip": "Keyboard: %s\\nClick: next · Right click: choose\\nSUPER + CTRL + Space", "class": "%s"}\n' \
        "$(short "$cur")" "$(label "$cur")" "$(short "$cur" | tr A-Z a-z)"
}

case "${1:-}" in
    next)   running; step 1 ;;
    prev)   running; step -1 ;;
    set)    running
            if [[ ${2:-} =~ ^[0-9]+$ ]]; then mapfile -t l < <(ims); [ -n "${l[$2 - 1]:-}" ] && switch_to "${l[$2 - 1]}"
            else switch_to "${2:?nome}"; fi ;;
    pick)   running; pick ;;
    status) status ;;
    *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
