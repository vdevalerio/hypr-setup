# fcitx5 (input methods)

Languages: Portuguese (ABNT2), English, Russian, Japanese (Mozc). Config:
`~/.config/fcitx5` (`profile` holds the ordered list).

| Keys | Action |
| --- | --- |
| `SUPER + CTRL + Space` | Next language |
| `SUPER + CTRL + SHIFT + Space` | Previous language |
| `SUPER + CTRL + 1/2/3/4` | Portuguese / English / Russian / Japanese |

`scripts/keyboard.sh` switches languages by name. Hyprland keybinds stay on the
`br` layout regardless of the active language, so shortcuts never break.

Japanese: type romaji, `Space` converts, `Enter` confirms. The candidate window
is themed from the system colors. `fcitx5-configtool` opens the GUI settings.
