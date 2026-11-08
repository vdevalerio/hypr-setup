# Helper scripts (`~/.config/hypr/scripts`)

Run any of them from a terminal; most take a sub-command.

| Script | Purpose |
| --- | --- |
| `wallpaper.sh` | Wallpapers (images, GIFs through `awww`, videos through `mpvpaper`) and the color theme: `pick`, `random`, `theme <id\|auto>` |
| `look.sh` | Font size, gaps, scale of all monitors: `font up\|down\|reset`, `gaps …`, `scale …` |
| `displays.sh` | Per-monitor settings; `displays.sh scale <monitor\|focused> up\|down\|reset\|<value>` scales one monitor |
| `controlcenter.sh` | Rofi control center (`SUPER + A`): display, theme, Bluetooth, tools |
| `displays.sh` | Monitor settings behind the control center |
| `brightness.sh` | Per-monitor brightness (internal and DDC/CI) |
| `osd.sh` | On-screen indicators for volume, mic, caps lock |
| `screenshot.sh` | `region`, `screen`, `edit` (satty) into `~/Pictures/Screenshots` |
| `record.sh` | Screen recording with gpu-screen-recorder into `~/Videos/Recordings` |
| `ocr.sh` | Text from a screen area (tesseract); `ocr.sh jpn` for Japanese |
| `clipboard.sh` | Clipboard history (cliphist + rofi) |
| `keybinds.sh` | The searchable keybind list |
| `keyboard.sh` | fcitx5 language switching |
| `tablet.sh` | Which monitor the Wacom / stylus pen is mapped to |
| `lock.sh`, `lockinfo.sh`, `avatar.sh` | Lock screen and its profile picture |
| `overview.sh` | Quickshell workspace overview |
| `powermenu.sh`, `power.sh`, `lid.sh` | Power menu, AC/battery, lid |
| `battery-watch.sh`, `health-watch.sh` | Warnings |
| `update.sh`, `updates.sh` | Safe system update (`update` alias) and the bar's pending-updates badge |
| `backup.sh` | restic backup to Google Drive through rclone (`backup setup`, `backup`) |
| `vpn.sh` | VPN status for the bar |
| `todo.sh` | To-do list (`todo` command, bar badge, `SUPER + CTRL + T` menu); see [todo](../todo/README.md) |
| `tmux-start.sh` | kitty's shell: opens every terminal inside tmux (attaches to a restored, unused session) |
| `voice.sh` | Piper text-to-speech voices |
| `sysmon.sh`, `media.sh`, `claude-usage.py` | Data for the bar islands |
| `bar.sh` | Supervisor that keeps Waybar running |
| `igpu.sh` | Run a program on the integrated GPU only |
| `sddm-sync.sh` | Mirror lock-screen look into the login screen |

## Notes

- Never start session daemons (waybar, mpvpaper, quickshell) from a plain shell:
  they outlive logout. Use `hyprctl dispatch 'hl.dsp.exec_cmd("…")'`.
- Everything long-running is wrapped in `igpu.sh` so only Hyprland touches the
  NVIDIA GPU, which keeps the dGPU asleep.
