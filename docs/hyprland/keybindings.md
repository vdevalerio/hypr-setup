# Keybindings

`SUPER` is the Windows/logo key. Hyprland binds always use the `br` layout, even
when fcitx5 is typing Russian or Japanese. Press `SUPER + F1` for the live list.

## Applications

| Keys | Action |
| --- | --- |
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + Space` / `SUPER + D` | App launcher (rofi) |
| `SUPER + SHIFT + Space` | Run a command |
| `ALT + Tab` | Window list (rofi) |
| `SUPER + Tab` | Workspace overview |
| `SUPER + E` | File manager (yazi in kitty) |
| `SUPER + B` | Browser (Brave) |
| `SUPER + V` | Clipboard history |
| `SUPER + SHIFT + V` | Text-to-speech voice picker |
| `SUPER + ;` | Emoji picker |
| `SUPER + =` | Calculator |
| `SUPER + N` / `SUPER + SHIFT + N` | Notification center / clear |
| `SUPER + SHIFT + B` | Toggle the bar |
| `SUPER + SHIFT + C` | Color picker (copies hex) |
| `SUPER + A` | Control center |
| `SUPER + CTRL + T` | To-do list (see [todo](../todo/README.md)) |
| `SUPER + F1` | Keybind list |

## Windows

| Keys | Action |
| --- | --- |
| `SUPER + Q` | Close |
| `SUPER + F` / `SUPER + M` | Fullscreen / maximize |
| `SUPER + T` | Toggle floating |
| `SUPER + C` | Center a floating window |
| `SUPER + P` | Pin to all workspaces |
| `SUPER + Y` | Toggle split direction |
| `SUPER + G` | Toggle tab group |
| `SUPER + ALT + Tab` | Next tab in a group |
| `SUPER + arrows` or `h/j/k/l` | Focus |
| `SUPER + SHIFT + arrows/hjkl` | Move window |
| `SUPER + CTRL + arrows/hjkl` | Resize (repeats while held) |
| `SUPER + R` | Resize mode: arrows/hjkl, `Esc` or `Enter` to leave |
| Mouse: `SUPER + left drag` / `right drag` | Move / resize |

Tab groups: `SUPER + G` groups the window with its neighbor; `SUPER + ALT + Tab`
and `SUPER + ALT + SHIFT + Tab` cycle the tabs forward and back.

## Workspaces

| Keys | Action |
| --- | --- |
| `SUPER + 1…0` | Go to workspace 1–10 **on this monitor** |
| `SUPER + SHIFT + 1…0` | Move the window to that workspace |
| `SUPER + , / .` or `Page Up / Down` | Previous / next workspace |
| `SUPER + '` | Back to the last workspace |
| `SUPER + W` | First empty workspace |
| `SUPER + O` | Focus the next monitor |
| `SUPER + SHIFT + O` | Move the window to the next monitor |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + ALT + S` | Send the window to the scratchpad |
| `SUPER + mouse wheel` | Previous / next workspace |

## Looks (saved in `look.conf`)

| Keys | Action |
| --- | --- |
| `SUPER + SHIFT + W` / `SUPER + CTRL + W` | Pick / random wallpaper |
| `SUPER + SHIFT + T` | Color theme (automatic or fixed) |
| `SUPER + ALT + = / - / 0` | Font size bigger / smaller / reset |
| `SUPER + CTRL + = / - / 0` | Window gaps (also the bar margin) |
| `SUPER + CTRL + ALT + = / - / 0` | Display scale of **all** monitors |
| `SUPER + SHIFT + ALT + = / - / 0` | Scale of the **focused monitor only** (`0` = default) |

## Keyboard languages (fcitx5)

| Keys | Action |
| --- | --- |
| `SUPER + CTRL + Space` | Next language |
| `SUPER + CTRL + SHIFT + Space` | Previous language |
| `SUPER + CTRL + 1/2/3/4` | Portuguese / English / Russian / Japanese |

## Capture

| Keys | Action |
| --- | --- |
| `Print` / `SUPER + SHIFT + S` | Screenshot a region |
| `SHIFT + Print` | All monitors |
| `CTRL + Print` | Focused monitor only |
| `SUPER + Print` | Region, then edit (satty) |
| `SUPER + ALT + R` | Start / stop screen recording |
| `SUPER + ALT + SHIFT + R` | Record a region |
| `SUPER + CTRL + S` | OCR: copy text from a screen area |

## Session

| Keys | Action |
| --- | --- |
| `SUPER + Esc` | Lock screen (normal: the system may suspend) |
| `SUPER + SHIFT + Esc` | Remote-safe lock: password required, system stays awake |
| `SUPER + X` | Power menu (includes **Reload Hyprland**: re-reads the config, closes nothing) |
| `SUPER + CTRL + Q` | Exit Hyprland |

## Media keys

Volume, mute, microphone mute, brightness (of the focused monitor), play/pause,
next and previous track all work from the keyboard's `XF86` keys and show an
on-screen indicator.
