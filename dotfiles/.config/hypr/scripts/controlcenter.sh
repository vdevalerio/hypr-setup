#!/usr/bin/env bash
# Central de controle (SUPER + A ou o botão 󰒓 na barra): os ajustes que não ficam na barra.
#
#   controlcenter.sh                  abre o menu principal (se já estiver aberto, fecha)
#   controlcenter.sh <menu> [linha]   abre direto: main | look | theme | power-profile | brightness | displays |
#                                     bluetooth | keyboard | tools  (ou display:<monitor>, brightness:<monitor>)
#   controlcenter.sh status           JSON para o módulo custom/control da Waybar
#
# Ajustes (fonte maior, brilho, liga/desliga...) mantêm o menu aberto: dá para repetir com Enter.

S=~/.config/hypr/scripts
panel() { echo "window {location: north east; anchor: north east; x-offset: -10px; y-offset: 48px; width: ${WIDTH}px;}
              element {padding: 6px 12px;}"; }

# ── Estado ────────────────────────────────────────────────────────────
dnd_on()   { [ "$(swaync-client -D -sw 2>/dev/null)" = true ]; }
awake_on() { ! pgrep -x hypridle >/dev/null; }
night_on() { pgrep -x hyprsunset >/dev/null; }
bt_on()    { timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; }
bt_connected() { timeout 2 bluetoothctl devices Connected 2>/dev/null | grep -q '^Device'; }
onoff()    { "$@" && echo on || echo off; }

wifi()       { nmcli -t -f TYPE,NAME connection show --active 2>/dev/null |
                 awk -F: '$1 ~ /wireless/ { print substr($2, 1, 16); f = 1; exit } END { if (!f) print "off" }'; }
volume()     { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null |
                 awk '{ printf "%d%%%s", $2 * 100, ($3 == "[MUTED]" ? " muted" : "") }'; }
brightness() { local v; v=$("$S/brightness.sh" get "$@" 2>/dev/null | head -1); echo "${v:-?}"; }
monitors()   { hyprctl monitors all -j | jq -r '.[].name'; }
mon_count()  { hyprctl monitors -j | jq length; }
dlabel()     { [[ $1 == eDP* ]] && { echo Laptop; return; }
               hyprctl monitors all -j | jq -r --arg n "$1" '.[] | select(.name == $n) | .model'; }
mon_json()   { hyprctl monitors all -j | jq -r --arg n "$1" ".[] | select(.name == \$n) | $2"; }
disp() { "$S/displays.sh" "$@"; }
battery()    { cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1; }
profile()    { powerprofilesctl get 2>/dev/null; }
THEME=~/.config/hypr/themes/theme.py
theme_mode() { local m; m=$(cat ~/.cache/wallpaper/theme-mode 2>/dev/null)
               case "$m" in ""|auto) echo auto ;; fixed) echo catppuccin-mocha ;; *) echo "$m" ;; esac; }
color_mode() { python3 "$THEME" name "$(theme_mode)" 2>/dev/null | sed 's/ (wallpaper)//'; }
scale_now()  { hyprctl monitors -j | jq -r '.[0].scale | . * 100 | round / 100'; }

look() { "$S/look.sh" "$@"; }
# Funções do keyboard.sh (siglas, nomes, lista de idiomas)
kb() { ( source <(sed -n '/^PROFILE=/p; /^short()/p; /^label()/p; /^ims()/p' "$S/keyboard.sh"); "$@" ); }
kb_now() { local c; c=$(fcitx5-remote -n 2>/dev/null) && [ -n "$c" ] && kb label "$c" || echo "off"; }
refresh_bar() { pkill -RTMIN+8 -x waybar 2>/dev/null; }

toggle_awake() {
    if awake_on; then setsid -f hypridle >/dev/null 2>&1
    else pkill -x hypridle; fi
}
toggle_night() {
    if night_on; then pkill -x hyprsunset
    else setsid -f hyprsunset -t 4500 >/dev/null 2>&1; fi
}
toggle_bt() {
    if bt_on; then bluetoothctl power off >/dev/null
    else rfkill unblock bluetooth 2>/dev/null; sleep 0.3; bluetoothctl power on >/dev/null; fi
}

# ── Menu genérico ─────────────────────────────────────────────────────
items=(); acts=(); PAD=20; COLS=1; WIDTH=470
esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; echo "${s//>/&gt;}"; }
# add <ícone> <nome> <valor à direita> <ação>   (ação com + na frente = reabre o menu depois)
add() {
    items+=("$(printf "%s  %-${PAD}s <span alpha=\"55%%\">%s</span>" "$1" "$2" "$(esc "$3")")")
    acts+=("$4")
}
# add_raw: igual, mas o valor já é markup (ex.: amostras de cor) e não fica apagado
add_raw() {
    items+=("$(printf "%s  %-${PAD}s %s" "$1" "$2" "$3")")
    acts+=("$4")
}

show() { # show <título> <nome do menu> [mensagem]
    local idx act args=()
    [ -n "${3:-}" ] && args=(-mesg "$3")
    idx=$(printf '%s\n' "${items[@]}" |
        rofi -dmenu -i -markup-rows -no-custom -format i -p "$1" -selected-row "${ROW:-0}" "${args[@]}" \
             -theme-str "$(panel) listview {lines: $(( (${#items[@]} + COLS - 1) / COLS )); columns: $COLS; flow: horizontal;}") || exit 0
    [ -n "$idx" ] || exit 0
    act=${acts[idx]}
    if [[ $act == +* ]]; then
        eval "${act#+}"
        refresh_bar
        exec "$0" "$2" "$idx"
    fi
    refresh_bar
    eval "$act"
}

# ── Menus ─────────────────────────────────────────────────────────────
main_menu() {
    add "󰏘" "Appearance"        "Aa $(look get font)% ›" "exec $0 look"
    add "$(dnd_on && echo 󰂛 || echo 󰂚)" "Do not disturb" "$(onoff dnd_on)" "+swaync-client -d -sw >/dev/null"
    add "󰅶" "Keep screen awake" "$(onoff awake_on)"  "+toggle_awake"
    add "󰖔" "Night light"       "$(onoff night_on)"  "+toggle_night"
    add "󰓅" "Power profile"     "$(profile) ›"       "exec $0 power-profile"
    add "󰃠" "Brightness"        "$( (( $(mon_count) > 1 )) && echo "per monitor" || echo "$(brightness focused)%") ›" "exec $0 brightness"
    add "󰍺" "Displays"          "$(mon_count) on ›"  "exec $0 displays"
    add "󰖩" "Wi-Fi"             "$(wifi)"            "setsid -f kitty --class nmtui-float -e nmtui"
    add "󰂯" "Bluetooth"         "$(onoff bt_on) ›"   "exec $0 bluetooth"
    add "󰕾" "Audio mixer"       "$(volume)"          "setsid -f pavucontrol"
    add "󰌌" "Keyboard"          "$(kb_now) ›"        "exec $0 keyboard"
    add "󰙨" "Tools"             "›"                  "exec $0 tools"
    local up; up=$(uptime -p | sed 's/^up //; s/ hours\?/h/; s/ minutes\?/m/; s/,//g')
    show "Control" main "󰀄  $USER   ·   󰁹 $(battery)%   ·   󰔟 up $up"
}

look_menu() {   # duas colunas: pares lado a lado
    PAD=10; COLS=2; WIDTH=660
    add "󰁍" "Back"      ""                     "exec $0 main 0"
    add "󰑓" "Reset"     "all"      "+look font reset; look gaps reset; look scale reset"
    add "󰛖" "Font +"    "$(look get font)%"    "+look font up"
    add "󰛗" "Font −"    ""                     "+look font down"
    add "󰕰" "Gaps +"    "$(look get gaps) px"  "+look gaps up"
    add "󰕰" "Gaps −"    ""                     "+look gaps down"
    add "󰍹" "Scale +"   "$(scale_now)"         "+look scale up"
    add "󰍹" "Scale −"   ""                     "+look scale down"
    add "󰕮" "Gaps"      "on/off"             "+look gaps toggle"
    add "󰍜" "Bar"       "on/off"          "+pkill -SIGUSR1 -x waybar"
    add "󰸉" "Wallpaper" "choose…"              "$S/wallpaper.sh pick"
    add "󰒝" "Wallpaper" "random"               "+$S/wallpaper.sh random"
    add "󰏘" "Theme"     "$(color_mode) ›"      "exec $0 theme"
    add "󰀄" "Photo"     "$([ -f ~/.face ] && echo change… || echo choose…)" "$S/avatar.sh pick"
    show "Appearance" look
}

theme_menu() {   # temas fixos (~/.config/hypr/themes/palettes) ou automático, com amostras de cor
    local cur id name cols dots c
    cur=$(theme_mode)
    PAD=22; WIDTH=520
    add "󰁍" "Back" "" "exec $0 look 12"
    add "$([ "$cur" = auto ] && echo 󰄬 || echo 󰸉)" "Automatic" "colors from the wallpaper" "+$S/wallpaper.sh theme auto"
    while IFS=$'\t' read -r id name cols; do
        dots=""
        for c in $cols; do dots+="<span foreground=\"#$c\">●</span> "; done
        add_raw "$([ "$cur" = "$id" ] && echo 󰄬 || echo 󰏘)" "$name" "$dots" "+$S/wallpaper.sh theme $id"
    done < <(python3 "$THEME" list)
    show "Theme" theme "Automatic follows each wallpaper · SUPER + SHIFT + T opens this menu"
}

power_profile_menu() {
    local cur p icon; cur=$(profile)
    add "󰁍" "Back" "" "exec $0 main 4"
    for p in performance balanced power-saver; do
        case $p in performance) icon=󰓅 ;; balanced) icon=󰾅 ;; *) icon=󰌪 ;; esac
        add "$icon" "$p" "$([ "$p" = "$cur" ] && echo "● active")" "powerprofilesctl set $p; exec $0 main 4"
    done
    show "Power profile" power-profile
}

brightness_menu() {   # um monitor: direto; vários: escolhe qual
    local m
    if (( $(mon_count) == 1 )); then brightness_mon "$(hyprctl monitors -j | jq -r '.[0].name')"; return; fi
    add "󰁍" "Back" "" "exec $0 main 5"
    for m in $(hyprctl monitors -j | jq -r '.[].name'); do
        add "󰍹" "$(dlabel "$m")" "$(brightness "$m")% ›" "exec $0 brightness:$m"
    done
    show "Brightness" brightness
}

brightness_mon() {
    local m=$1 b back="exec $0 main 5"
    (( $(mon_count) > 1 )) && back="exec $0 brightness"
    add "󰁍" "Back"     ""                     "$back"
    add "󰃠" "Brighter" "$(brightness "$m")%"  "+$S/brightness.sh up $m 10"
    add "󰃞" "Dimmer"   ""                     "+$S/brightness.sh down $m 10"
    for b in 100 75 50 25 10; do
        add "󰃟" "$b%" "" "+$S/brightness.sh set $b $m"
    done
    show "Brightness: $(dlabel "$m")" "brightness:$m"
}

displays_menu() {
    local m
    add "󰁍" "Back" "" "exec $0 main 6"
    for m in $(monitors); do
        add "$([ "$(mon_json "$m" .disabled)" = true ] && echo 󰶐 || echo 󰍹)" "$(dlabel "$m") ($m)" \
            "$(disp info "$m") ›" "exec $0 display:$m"
    done
    add "󰑓" "All automatic" "reset" "+disp reset-all"
    PAD=24; WIDTH=600
    show "Displays" displays "Each monitor has its own workspaces 1–10 · SUPER + O: next monitor"
}

display_menu() {
    local m=$1 o name=$(dlabel "$1")
    PAD=24; WIDTH=560
    add "󰁍" "Back" "" "exec $0 displays"
    if [ "$(mon_json "$m" .disabled)" = true ]; then
        add "󰍹" "Turn on" "" "disp enable $m; exec $0 displays"
    else
        add "󰃠" "Brightness"  "$(brightness "$m")% ›"                                "exec $0 brightness:$m"
        add "󰍹" "Resolution"  "$(mon_json "$m" '"\(.width)×\(.height)@\(.refreshRate | round)"') ›" "exec $0 display-mode:$m"
        add "󰐕" "Scale"       "$(mon_json "$m" '.scale * 100 | round / 100') ›"      "exec $0 display-scale:$m"
        add "󰑵" "Rotation"    "$(mon_json "$m" '[0, 90, 180, 270][.transform % 4]')° ›" "exec $0 display-rotate:$m"
        for o in $(hyprctl monitors -j | jq -r '.[].name'); do
            [ "$o" = "$m" ] && continue
            add "󰁍" "Left of $(dlabel "$o")"  "" "+disp place $m left $o"
            add "󰁔" "Right of $(dlabel "$o")" "" "+disp place $m right $o"
            add "󰁝" "Above $(dlabel "$o")"    "" "+disp place $m above $o"
            add "󰁅" "Below $(dlabel "$o")"    "" "+disp place $m below $o"
            if [ "$(mon_json "$m" .mirrorOf)" = "$o" ]; then
                add "󰍺" "Stop mirroring" "" "+disp unset $m mirror"
            else
                add "󰍺" "Mirror $(dlabel "$o")" "same image" "+disp set $m mirror $o"
            fi
        done
        (( $(mon_count) > 1 )) && add "󰶐" "Turn off" "" "disp disable $m; exec $0 displays"
    fi
    add "󰑓" "Reset to automatic" "" "+disp reset $m"
    show "$name ($m)" "display:$m" "$(mon_json "$m" .description)"
}

display_mode_menu() {
    local m=$1 cur mode
    cur=$(mon_json "$m" '"\(.width)x\(.height)@\(.refreshRate * 100 | round / 100)"')
    add "󰁍" "Back" "" "exec $0 display:$m 2"
    add "󰑓" "Automatic" "preferred" "disp unset $m mode; exec $0 display:$m 2"
    while read -r mode; do
        add "󰍹" "${mode/x/×}" "$([ "$mode" = "$cur" ] && echo "● active")" "disp set $m mode $mode; exec $0 display:$m 2"
    done < <(mon_json "$m" '.availableModes[] | sub("Hz$"; "") | split("@") | "\(.[0])@\(.[1] | tonumber * 100 | round / 100)"' | awk '!seen[$0]++')
    show "Resolution: $(dlabel "$m")" "display-mode:$m"
}

display_scale_menu() {
    local m=$1 cur s
    cur=$(mon_json "$m" '.scale * 100 | round / 100')
    add "󰁍" "Back" "" "exec $0 display:$m 3"
    add "󰑓" "Default" "global $(look get scale)" "disp unset $m scale; exec $0 display:$m 3"
    for s in 1 1.2 1.25 1.333333 1.5 1.6 2; do
        add "󰐕" "×$s" "$(awk -v a="$s" -v b="$cur" 'BEGIN { if ((a - b) ^ 2 < 0.0001) print "● active" }')" \
            "disp set $m scale $s; exec $0 display:$m 3"
    done
    show "Scale: $(dlabel "$m")" "display-scale:$m"
}

display_rotate_menu() {
    local m=$1 cur t
    cur=$(mon_json "$m" '.transform % 4')
    add "󰁍" "Back" "" "exec $0 display:$m 4"
    for t in 0 1 2 3; do
        add "󰑵" "$(( t * 90 ))°" "$([ "$t" = "$cur" ] && echo "● active")" "disp set $m transform $t; exec $0 display:$m 4"
    done
    show "Rotation: $(dlabel "$m")" "display-rotate:$m"
}

bluetooth_menu() {
    add "󰁍" "Back"               ""                  "exec $0 main 8"
    add "󰂯" "Bluetooth"          "$(onoff bt_on)"    "+toggle_bt"
    add "󰂱" "Devices / pairing"  ""                  "setsid -f blueman-manager"
    show "Bluetooth" bluetooth
}

keyboard_menu() {
    local cur im; cur=$(fcitx5-remote -n 2>/dev/null)
    add "󰁍" "Back" "" "exec $0 main 10"
    while read -r im; do
        add "$(kb short "$im")" "$(kb label "$im")" "$([ "$im" = "$cur" ] && echo "● active")" \
            "$S/keyboard.sh set $im; exec $0 main 10"
    done < <(kb ims)
    add "󰒓" "Input method settings" "" "setsid -f fcitx5-configtool"
    show "Keyboard" keyboard
}

tools_menu() {
    add "󰁍" "Back"                ""                 "exec $0 main 11"
    add "󰹑" "Screenshot: region"  "Print"            "sleep 0.3; $S/screenshot.sh region"
    add "󰹑" "Screenshot: edit"    "SUPER+Print"      "sleep 0.3; $S/screenshot.sh edit"
    add "󰑋" "Record screen"       "SUPER+ALT+R"      "sleep 0.3; $S/record.sh screen"
    add "󰑋" "Record screen + mic" ""                 "sleep 0.3; $S/record.sh screen mic"
    add "󰑋" "Record region"       "SUPER+ALT+SHIFT+R" "sleep 0.3; $S/record.sh region"
    add "󰊄" "Copy text (OCR)"     "SUPER+CTRL+S"     "sleep 0.3; $S/ocr.sh"
    add "󰊄" "Copy text: 日本語"    "Japanese"         "sleep 0.3; $S/ocr.sh jpn"
    add "󰊄" "Copy text: Русский"  "Russian"          "sleep 0.3; $S/ocr.sh rus"
    add "󰈋" "Color picker"        "SUPER+SHIFT+C"    "sleep 0.3; hyprpicker -a"
    add "󰅌" "Clipboard history"   "SUPER+V"          "$S/clipboard.sh"
    add "󰞅" "Emoji"               "SUPER+;"          "rofi -show emoji -modi emoji"
    add "󰃬" "Calculator"          "SUPER+="          "rofi -show calc -modi calc -no-show-match -no-sort"
    add "󰍛" "System monitor"      "btop"             "setsid -f kitty --class btop-float -e btop"
    add "󰌌" "Keybinds"            "SUPER+F1"         "$S/keybinds.sh"
    add "󰚰" "System update"       "update"           "setsid -f kitty --class btop-float -e $S/update.sh"
    add "󰁯" "Backup now"          "$(cut -d' ' -f2- ~/.cache/backup-last 2>/dev/null || echo never)" "setsid -f $S/backup.sh run"
    show "Tools" tools
}

status() {
    local icons=() tips=("Control center (SUPER + A)") text
    awake_on && { icons+=("󰅶"); tips+=("Keep screen awake: on"); }
    night_on && { icons+=("󰖔"); tips+=("Night light: on"); }
    case "$(profile)" in
        performance) icons+=("󰓅"); tips+=("Power profile: performance") ;;
        power-saver) icons+=("󰌪"); tips+=("Power profile: power saver") ;;
    esac
    bt_connected && { icons+=("󰂱"); tips+=("Bluetooth device connected"); }
    text="${icons[*]}"
    printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' \
        "${text:+$text  }󰒓" "$(IFS=$'\n'; echo "${tips[*]}" | sed ':a;N;$!ba;s/\n/\\n/g')" \
        "$([ ${#icons[@]} -gt 0 ] && echo active || echo idle)"
}

ROW=${2:-0}
case "${1:-}" in
    "")            pkill -x rofi && exit 0; main_menu ;;
    main)          main_menu ;;
    look)          look_menu ;;
    theme)         theme_menu ;;
    power-profile) power_profile_menu ;;
    brightness)    brightness_menu ;;
    brightness:*)  brightness_mon "${1#brightness:}" ;;
    displays)      displays_menu ;;
    display:*)     display_menu "${1#display:}" ;;
    display-mode:*)   display_mode_menu "${1#display-mode:}" ;;
    display-scale:*)  display_scale_menu "${1#display-scale:}" ;;
    display-rotate:*) display_rotate_menu "${1#display-rotate:}" ;;
    bluetooth)     bluetooth_menu ;;
    keyboard)      keyboard_menu ;;
    tools)         tools_menu ;;
    status)        status ;;
    *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
