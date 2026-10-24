#!/usr/bin/env bash
# Lista pesquisável de todos os atalhos (SUPER + F1)
pkill -x rofi && exit 0
hyprctl binds -j | jq -r '
  def mods: [ (if (.modmask / 64 | floor) % 2 == 1 then "SUPER" else empty end),
              (if (.modmask / 4  | floor) % 2 == 1 then "CTRL"  else empty end),
              (if (.modmask / 8  | floor) % 2 == 1 then "ALT"   else empty end),
              (if  .modmask % 2 == 1               then "SHIFT" else empty end) ];
  .[]
  | select((.submap // "") == "")
  | select((.description // "") != "")
  | ((mods + [.key]) | join(" + ")) as $k
  | "\($k)\t\(.description)"' |
  awk -F'\t' '!seen[$2 $1]++ { printf "%-28s  %s\n", $1, $2 }' |
  rofi -dmenu -i -p "Keybinds" -no-custom -theme-str 'window {width: 760px;} listview {lines: 14;} element-text {font: @ui-font-small;}' > /dev/null
