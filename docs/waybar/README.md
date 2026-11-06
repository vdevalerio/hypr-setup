# Waybar

Top bar made of floating "islands". Config: `~/.config/waybar/config.jsonc`,
style in `style.css`; `colors.css` and `font.css` are generated. It runs under
`scripts/bar.sh`, a supervisor that restarts it if it crashes.

| Island | Content |
| --- | --- |
| Left | Launcher button, workspaces, submap indicator (e.g. resize mode), then the focused window title |
| Center | Clock (calendar in the tooltip) and the now-playing track (`playerctl`) |
| Tray | Drawer: toggle button + tray icons |
| Monitor | CPU, GPU, temperature, memory, disk, Claude usage |
| Status | To-do count, updates badge, VPN, volume, battery |
| Actions | Recording indicator, notification center, control center, power menu |

## Mouse

| Where | Action |
| --- | --- |
| Workspaces | Click to switch; right-click lists the open windows |
| Volume | Click mute · right-click pavucontrol · scroll volume |
| Battery | Scroll changes the brightness of the monitor under the cursor |
| To-do | Hover for the tasks · click opens the to-do menu ([todo](../todo/README.md)) |
| Clock | Hover for the calendar |
| CPU / memory / disk | Click opens the system monitor (`sysmon.sh top`) |

`SUPER + SHIFT + B` hides/shows the bar.

## Long titles and big fonts

The bar cannot scroll, so when the font is bigger (`SUPER + ALT + =`) the right end can be pushed
off screen. To prevent it, the window title is cut at 18 characters and the music title length shrinks
with the font (`2400 / font %` characters, at least 12; `scripts/media.sh`). If it still overflows at a
very large font, lower `max-length` of `hyprland/window` in `config.jsonc` or remove a module from the
Monitor island.

## Reloading

- CSS reloads by itself.
- Config: `pkill -USR2 -x waybar`.
- To start it from a script use `hyprctl dispatch 'hl.dsp.exec_cmd("…")'`.

## Pitfalls

- `on-click` commands must be wrapped in `setsid -f` or they freeze.
- The packaged `waybar` 0.15 cannot switch workspaces under a Lua config, so
  `waybar-git` is used until 0.16.
- The built-in `mpris` module crashes; `custom/media` is used instead.
