# Rofi

Launcher and menu framework. Everything pop-up on this desktop that looks like a
list is rofi: launcher, window list, clipboard, emoji, calculator, power menu,
control center, keybind list, wallpaper and theme pickers.

| Keys | Menu |
| --- | --- |
| `SUPER + Space` / `SUPER + D` | Applications |
| `SUPER + SHIFT + Space` | Run a command |
| `ALT + Tab` | Open windows |
| `SUPER + V` | Clipboard history (`Enter` pastes, `Shift+Delete` removes an item) |
| `SUPER + ;` | Emoji |
| `SUPER + =` | Calculator (`rofi-calc`) |
| `SUPER + A` | Control center |
| `SUPER + X` | Power menu |
| `SUPER + F1` | Keybinds |

Inside any menu: type to filter, `↑`/`↓` or `Ctrl+j/k` to move, `Enter` to accept,
`Esc` to close (clicking outside also closes it).

## Files

`~/.config/rofi`: `config.rasi` (modes, behavior), `theme.rasi` (layout),
`colors.rasi` and `font.rasi` (generated; do not edit).

## Tips

- Close with the same key (the binds toggle: `pkill -x rofi || rofi …`).
- Rofi 2.0 does not allow `@references` inside `linear-gradient()`; test theme
  edits by opening a menu.
