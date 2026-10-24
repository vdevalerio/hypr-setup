#!/usr/bin/env bash
# Janelas abertas agrupadas por workspace (clique direito nos workspaces da barra).
# Enter vai para a janela escolhida. Com vários monitores, mostra também o monitor (M1 = notebook,
# M2 = o próximo...: workspaces 1–10 são do M1, 11–20 do M2, como em workspaces.lua).
pkill -x rofi && exit 0

clients=$(hyprctl clients -j)
monitors=$(hyprctl monitors -j | jq 'length')

# Uma linha por janela: workspace (1–10 de cada monitor), app e título; endereço vai à parte
rows=$(jq -r --argjson multi "$((monitors > 1))" '
    def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
    [ .[] | select(.workspace.id != -1 and .mapped) ]
    | sort_by(.workspace.id, .focusHistoryID)[]
    | (if .workspace.id < 0 then "S" else (((.workspace.id - 1) % 10) + 1 | tostring) end) as $ws
    | [ .address,
        ("<b>" + $ws + "</b>" + (if $multi == 1 and .workspace.id > 0 then "<span alpha=\"55%\"> · M" + ((.workspace.id - 1) / 10 | floor + 1 | tostring) + "</span>" else "" end)
         + "   " + (.class | esc) + "  <span alpha=\"60%\">" + (.title | .[0:70] | esc) + "</span>"),
        (.class | ascii_downcase) ]
    | @tsv' <<<"$clients")

[ -z "$rows" ] && { notify-send -a windows "Windows" "No open windows"; exit 0; }

idx=$(cut -f2,3 <<<"$rows" | while IFS=$'\t' read -r label icon; do
        printf '%s\0icon\x1f%s\n' "$label" "$icon"
      done | rofi -dmenu -i -markup-rows -show-icons -format i -p "Windows" \
                  -mesg "Open windows by workspace · Enter: go to window")
[ -z "$idx" ] && exit 0

addr=$(sed -n "$((idx + 1))p" <<<"$rows" | cut -f1)
hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null
