#!/usr/bin/env bash
# Open windows grouped by workspace (right-click the workspaces in the bar).
# Enter jumps to the chosen window. With multiple monitors, also shows the monitor (M1 = laptop,
# M2 = the next one...: workspaces 1–10 belong to M1, 11–20 to M2, as in workspaces.lua).
pkill -x rofi && exit 0

clients=$(hyprctl clients -j)
monitors=$(hyprctl monitors -j | jq 'length')

# One line per window: workspace (1–10 of each monitor), app and title; address goes separately
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
