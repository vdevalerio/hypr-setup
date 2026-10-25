#!/usr/bin/env bash
# Ajustes visuais ao vivo: tamanho das fontes, espaço entre janelas (gaps) e escala da tela.
# Os valores ficam em ~/.config/hypr/look.conf (o hyprland.lua lê o mesmo arquivo no login).
#
#   look.sh font  up|down|reset          fontes: barra, menus, notificações, terminal e apps GTK
#   look.sh gaps  up|down|reset|toggle   espaço entre as janelas
#   look.sh scale up|down|reset          escala da tela (aumenta/diminui tudo; reset = automática)
#   look.sh apply                        regera os arquivos de fonte (no login)
#   look.sh get   font|gaps|scale        mostra o valor atual

CONF=~/.config/hypr/look.conf
DEFAULTS=(font=100 gaps=5 scale=auto)
SCALES=(1 1.2 1.25 1.333333 1.5 1.6 2)   # escalas que dão pixels inteiros em telas 1080p/1440p/4K
NOTIFY_ID="${XDG_RUNTIME_DIR:-/tmp}/look-notify-id"

default() { local kv; for kv in "${DEFAULTS[@]}"; do [ "${kv%%=*}" = "$1" ] && echo "${kv#*=}"; done; }

get() {
    local v
    v=$(sed -n "s/^$1=//p" "$CONF" 2>/dev/null | tail -1)
    echo "${v:-$(default "$1")}"
}

put() {
    [ -f "$CONF" ] || printf '# Ajustes visuais (alterados pelos atalhos, veja scripts/look.sh)\n' > "$CONF"
    if grep -q "^$1=" "$CONF"; then sed -i "s/^$1=.*/$1=$2/" "$CONF"; else echo "$1=$2" >> "$CONF"; fi
}

# Tamanho base (em 100%) multiplicado pela escala das fontes
px()  { awk -v b="$1" -v f="$(get font)" 'BEGIN { printf "%.0f", b * f / 100 }'; }
pt()  { awk -v b="$1" -v f="$(get font)" 'BEGIN { printf "%.1f", b * f / 100 }'; }

osd() { # osd <título> <texto> [valor 0-100]
    local id args=(-a look -t 1500 -p)
    id=$(cat "$NOTIFY_ID" 2>/dev/null)
    [ -n "$id" ] && args+=(-r "$id")
    [ -n "${3:-}" ] && args+=(-h "int:value:$3")
    notify-send "${args[@]}" "$1" "$2" > "$NOTIFY_ID" 2>/dev/null
}

write_fonts() {
    cat > ~/.config/waybar/font.css <<EOF
/* GERADO por scripts/look.sh — não edite (SUPER + ALT + = / -) */
* { font-size: $(px 13)px; }
#custom-launcher { font-size: $(px 17)px; }
#custom-tray-toggle, #custom-notification, #custom-control, #custom-power { font-size: $(px 15)px; }
EOF
    cat > ~/.config/swaync/font.css <<EOF
/* GERADO por scripts/look.sh — não edite (SUPER + ALT + = / -) */
* { font-size: $(px 13)px; }
.summary { font-size: $(px 14)px; }
.time { font-size: $(px 11)px; }
.widget-title > label { font-size: $(px 18)px; }
EOF
    cat > ~/.config/rofi/font.rasi <<EOF
/* GERADO por scripts/look.sh — não edite (SUPER + ALT + = / -) */
* {
    ui-font:       "JetBrainsMono Nerd Font $(pt 12)";
    ui-font-bold:  "JetBrainsMono Nerd Font Bold $(pt 12)";
    ui-font-small: "JetBrainsMono Nerd Font $(pt 11)";
}
EOF
    [ -f ~/.config/fcitx5/conf/classicui.conf ] &&
        sed -i "s/^Font=.*/Font=\"Noto Sans CJK JP $(px 11)\"/; s/^MenuFont=.*/MenuFont=\"Noto Sans $(px 10)\"/" \
            ~/.config/fcitx5/conf/classicui.conf
    [ -f ~/.config/qt6ct/qt6ct.conf ] &&
        sed -i -E "s/^(general|fixed)=\"([^,]+),[^,]+,/\\1=\"\\2,$(pt 11),/" ~/.config/qt6ct/qt6ct.conf
    printf '# GERADO por scripts/look.sh — não edite (SUPER + ALT + = / -)\nfont_size %s\n' "$(pt 11.5)" \
        > ~/.config/kitty/font.conf
    gsettings set org.gnome.desktop.interface text-scaling-factor \
        "$(awk -v f="$(get font)" 'BEGIN { printf "%.2f", f / 100 }')" 2>/dev/null
}

font() {
    local f; f=$(get font)
    case "$1" in
        up)    f=$(( f + 10 > 200 ? 200 : f + 10 )) ;;
        down)  f=$(( f - 10 < 50 ? 50 : f - 10 )) ;;
        reset) f=$(default font) ;;
        *) usage ;;
    esac
    put font "$f"
    write_fonts
    pkill -SIGUSR2 -x waybar          # recarrega a barra
    swaync-client -rs >/dev/null 2>&1 # recarrega o CSS das notificações
    pkill -SIGUSR1 -x kitty           # terminais abertos releem font.conf
    fcitx5-remote -r 2>/dev/null      # janela de candidatos do japonês
    hyprctl eval "hl.config({ group = { groupbar = { font_size = $(px 11) } } })" >/dev/null
    osd "Font size" "$f%  ·  apps GTK abertos atualizam ao reabrir" "$(( (f - 50) * 100 / 150 ))"
}

# gaps_out acompanha gaps_in na proporção 5 → 12 (mesma conta no hyprland.lua)
gaps_out() { awk -v g="$1" 'BEGIN { printf "%d", g * 2.4 + 0.5 }'; }

# Margens da barra = gaps_out (as ilhas alinham com a borda das janelas); mínimo 4 px sem gaps
bar_margin() {
    local m=$(( $1 < 4 ? 4 : $1 ))
    sed -i -E "s/(\"margin-(top|left|right)\": )[0-9]+/\1$m/" ~/.config/waybar/config.jsonc
    pkill -SIGUSR2 -x waybar
}

gaps() {
    local g; g=$(get gaps)
    case "$1" in
        up)     g=$(( g + 1 > 30 ? 30 : g + 1 )) ;;
        down)   g=$(( g - 1 < 0 ? 0 : g - 1 )) ;;
        reset)  g=$(default gaps) ;;
        toggle) if [ "$g" -gt 0 ]; then put gaps_last "$g"; g=0; else g=$(get gaps_last); g=${g:-$(default gaps)}; fi ;;
        *) usage ;;
    esac
    put gaps "$g"
    hyprctl eval "hl.config({ general = { gaps_in = $g, gaps_out = $(gaps_out "$g") } })" >/dev/null
    bar_margin "$(gaps_out "$g")"
    osd "Window gaps" "inner $g px  ·  outer $(gaps_out "$g") px" "$(( g * 100 / 30 ))"
}

scale() {
    local s cur i n=${#SCALES[@]} idx=0
    s=$(get scale)
    cur=$s
    [ "$cur" = auto ] && cur=$(hyprctl monitors -j | jq -r '.[0].scale')
    # posição da escala atual na lista (a mais próxima)
    for i in "${!SCALES[@]}"; do
        awk -v a="${SCALES[i]}" -v b="$cur" 'BEGIN { exit !(a <= b + 0.01) }' && idx=$i
    done
    case "$1" in
        up)    s=${SCALES[$(( idx + 1 < n ? idx + 1 : n - 1 ))]} ;;
        down)  s=${SCALES[$(( idx - 1 < 0 ? 0 : idx - 1 ))]} ;;
        reset) s=auto ;;
        *) usage ;;
    esac
    put scale "$s"
    local lua=$s; [ "$s" = auto ] && lua='"auto"'
    hyprctl eval "hl.monitor({ output = \"\", mode = \"preferred\", position = \"auto\", scale = $lua })" >/dev/null
    hyprctl eval 'require("monitors").apply()' >/dev/null   # monitores com ajustes próprios (Displays)
    sleep 0.3
    osd "Display scale" "$s  ($(hyprctl monitors -j | jq -r '.[0] | "\(.width / .scale | floor)×\(.height / .scale | floor)"') px úteis)"
}

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

case "${1:-}" in
    font)  font "${2:-}" ;;
    gaps)  gaps "${2:-}" ;;
    scale) scale "${2:-}" ;;
    apply) write_fonts ;;
    get)   get "${2:-font}" ;;
    *) usage ;;
esac
pkill -RTMIN+8 -x waybar 2>/dev/null   # atualiza o ícone da central de controle
exit 0
