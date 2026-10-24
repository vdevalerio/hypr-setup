#!/usr/bin/env bash
# Wallpaper: imagens e GIFs animados (awww), vídeos (mpvpaper),
# e o tema de cores do sistema: automático (do wallpaper) ou um tema fixo (~/.config/hypr/themes).
#
#   wallpaper.sh set <arquivo>          aplica wallpaper e recolore o sistema
#   wallpaper.sh pick                   seletor visual (rofi)
#   wallpaper.sh random                 wallpaper aleatório da pasta
#   wallpaper.sh restore                no login: reaplica o último wallpaper
#   wallpaper.sh theme auto|<tema>|toggle  tema de cores: auto (do wallpaper), um tema fixo
#                                         (theme.py list) ou alterna entre auto e o último fixo
#
# Os wallpapers ficam em ~/Pictures/Wallpapers (png, jpg, webp, gif, mp4, webm, mkv, mov).

WALLDIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Wallpapers"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
CURRENT="$STATE/current"
LOCKBG="$STATE/lock.png"   # fundo da tela de bloqueio (hyprlock.conf)
MODE_FILE="$STATE/theme-mode"      # "auto" ou o id de um tema fixo
LAST_FIXED="$STATE/theme-last"     # último tema fixo usado (para o "toggle")
THEME=~/.config/hypr/themes/theme.py
DEFAULT="$WALLDIR/aurora.mp4"
# Escolha atual guardada também no look.conf (vai junto no hypr-setup): numa máquina nova
# o restore usa o mesmo wallpaper e o mesmo modo de cor.
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

# Primeiro quadro (ou quadro em 1s nos vídeos) como PNG
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
            # Um mpvpaper por monitor. -p pausa o vídeo só no monitor em que ele está coberto
            # (ex.: janela em tela cheia). Não usar "-a FULL": ele pausa todos os monitores
            # se houver qualquer janela em tela cheia, mesmo num workspace escondido.
            # 9>&- e setsid: o mpvpaper não herda a trava do script nem o terminal
            local out
            for out in $(hyprctl monitors -j | jq -r '.[].name'); do
                setsid -f mpvpaper -f -p \
                    -o "no-audio --loop-file=inf --hwdec=auto --panscan=1.0 --really-quiet" \
                    "$out" "$f" </dev/null >/dev/null 2>&1 9>&-
            done
            sleep 0.8 # deixa o vídeo aparecer antes de tirar a imagem anterior (sem piscar)
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

# Quadro do wallpaper (imagem, GIF ou vídeo) para o fundo da tela de bloqueio
lock_bg() { frame "$1" "$LOCKBG.tmp.png" 2560 && mv -f "$LOCKBG.tmp.png" "$LOCKBG"; }

remember() { # remember <chave> <valor>  (grava no look.conf)
    [ -f "$LOOK" ] || return 0
    if grep -q "^$1=" "$LOOK"; then sed -i "s|^$1=.*|$1=$2|" "$LOOK"; else echo "$1=$2" >> "$LOOK"; fi
}
remembered() { sed -n "s/^$1=//p" "$LOOK" 2>/dev/null | tail -1; }

reload_apps() {
    hyprctl reload >/dev/null
    pkill -SIGUSR2 -x waybar        # recarrega estilo da barra
    swaync-client -rs >/dev/null 2>&1
    pkill -SIGUSR1 -x kitty         # recarrega cores dos terminais abertos
    ~/.config/hypr/scripts/sddm-sync.sh 9>&- &  # tela de login: fundo e cores novos (sem herdar a trava)
    fcitx5-remote -r 2>/dev/null    # tema da janela de candidatos (japonês)
}

# Tema atual: "auto" ou id de tema fixo ("fixed" = versões antigas = Catppuccin)
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

# Evita duas trocas ao mesmo tempo (ex.: clicar várias vezes)
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
            # máquina nova: modo de cor e wallpaper lembrados no look.conf, senão o padrão
            [ -f "$MODE_FILE" ] || [ -z "$(remembered colors)" ] || remembered colors > "$MODE_FILE"
            f="$WALLDIR/$(remembered wallpaper)"
            [ -f "$f" ] || f=$DEFAULT
            [ -f "$f" ] || f=$(list_walls | head -1)
            [ -n "$f" ] && set_wall "$f"
        fi ;;
    *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
