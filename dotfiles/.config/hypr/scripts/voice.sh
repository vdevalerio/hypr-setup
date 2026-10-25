#!/usr/bin/env bash
# Text-to-speech voice (Piper, via the sd_piper speech-dispatcher module).
# One voice per language, stored in ~/.config/piper-speechd/voices.json;
# the module re-reads it on every utterance, so no restart is needed.
#
#   voice.sh pick            menu (rofi): choose a voice (SUPER + SHIFT + V)
#   voice.sh set <voice>     direct, e.g. voice.sh set en_US-lessac-high
#   voice.sh list            installed voices, one per line

CONF=~/.config/piper-speechd/voices.json
DIRS=(~/.local/share/piper /usr/share/piper-voices)
SAMPLE_en="The quick brown fox jumps over the lazy dog."
SAMPLE_pt="A rápida raposa marrom pula sobre o cão preguiçoso."

voices() { find "${DIRS[@]}" -name '*.onnx' -printf '%f\n' 2>/dev/null | sed 's/\.onnx$//' | sort -u; }
active() { jq -r --arg l "$1" '.[$l] // empty' "$CONF" 2>/dev/null; }

set_voice() { # <voice id>
    local id=$1 lang=${1%%_*} tmp
    voices | grep -qx "$id" || { notify-send -a voice "Voice" "Unknown voice: $id"; exit 1; }
    mkdir -p "${CONF%/*}"
    tmp=$(mktemp)
    jq --arg l "$lang" --arg v "$id" '. + {($l): $v}' "$CONF" 2>/dev/null > "$tmp" || echo "{\"$lang\": \"$id\"}" > "$tmp"
    mv "$tmp" "$CONF"
    notify-send -a voice -t 2000 "󰔊  Voice" "${lang^^}: $id"
    local s="SAMPLE_$lang"
    spd-say -l "$lang" "${!s:-$SAMPLE_en}" >/dev/null 2>&1
}

pick() {
    pkill -x rofi && exit 0
    local list=() rows=() id lang name q mark idx
    mapfile -t list < <(voices)
    for id in "${list[@]}"; do
        lang=${id%%_*}; IFS=- read -r _ name q <<<"$id"
        mark=; [ "$(active "$lang")" = "$id" ] && mark="● active"
        rows+=("$(printf '%s   %-14s %-8s <span alpha="55%%">%s</span>' "${lang^^}" "$name" "$q" "$mark")")
    done
    [ ${#rows[@]} -gt 0 ] || { notify-send -a voice "Voice" "No Piper voices installed"; exit 1; }
    idx=$(printf '%s\n' "${rows[@]}" | rofi -dmenu -i -markup-rows -no-custom -format i -p "Voice" \
        -theme-str "window {width: 520px;} listview {lines: $(( ${#rows[@]} > 12 ? 12 : ${#rows[@]} ));}") || exit 0
    [ -n "$idx" ] && set_voice "${list[idx]}"
}

case "${1:-}" in
    pick) pick ;;
    set)  set_voice "${2:?voice id}" ;;
    list) voices ;;
    *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
