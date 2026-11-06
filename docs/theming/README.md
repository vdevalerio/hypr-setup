# Theming

One color source drives the whole desktop.

## Choosing a theme

| Keys | Action |
| --- | --- |
| `SUPER + SHIFT + T` | Theme menu: **auto** or a fixed palette |
| `SUPER + SHIFT + W` | Choose a wallpaper |
| `SUPER + CTRL + W` | Random wallpaper |

```sh
python3 ~/.config/hypr/themes/theme.py list          # themes and swatches
~/.config/hypr/scripts/wallpaper.sh theme nord       # fixed theme
~/.config/hypr/scripts/wallpaper.sh theme auto       # from the wallpaper
```

Fixed themes (`themes/palettes/*.txt`): catppuccin-mocha, dracula, everforest,
gruvbox, kanagawa, nord, rose-pine, tokyo-night. **auto** runs k-means on the
wallpaper to build a palette.

## What gets colored

`theme.py` writes: Hyprland (`colors.lua`), hyprlock, Waybar, SwayNC, Rofi, kitty,
tmux, GTK 3/4, Qt (qt6ct), btop, zathura, Quickshell, fcitx5, SDDM, and Neovim
reads `colors.lua`. lazygit and yazi use the terminal's ANSI colors and follow
automatically. Accents are a **mauve → blue gradient** everywhere.

## Creating a palette

Copy any file in `themes/palettes/` and change the 26 named colors (Catppuccin
names: `mauve` is the main accent, `blue` the second tone, `base`/`mantle`/`crust`
the backgrounds).

## Sizes

`scripts/look.sh` keeps font %, gaps and scale in `look.conf` and writes
`font.css`, `font.rasi` and `font.conf`. Never hardcode font sizes in style files.
