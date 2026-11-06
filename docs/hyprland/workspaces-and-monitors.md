# Workspaces and monitors

## Per-monitor workspaces

Each monitor owns a block of ten workspaces, so `SUPER + 3` always means "the
third workspace of the monitor I am on":

| Monitor | Workspaces |
| --- | --- |
| Internal panel (eDP-1) | 1–10 |
| Next monitor | 11–20 |
| Third monitor | 21–30 |

Monitors are ordered internal first, then by connector name. Workspaces 1–5 are
persistent (they exist even when empty). Logic: `workspaces.lua`.

`SUPER + , / .` and `Page Up/Down` move only through the focused monitor's own
workspaces. Right-clicking the workspaces on the bar lists every open window
(`scripts/windows.sh`); `Enter` jumps to it.

## Monitors

`monitors.lua` applies `~/.config/hypr/monitors.conf`, one section per monitor
keyed by its description, so settings survive port changes. Edit it through
**Control center → Displays** (`SUPER + A`), which writes the file and applies
it immediately (`scripts/displays.sh`).

Scale is global and automatic by default; `SUPER + CTRL + ALT + = / - / 0` changes
it live for **all** monitors and `0` goes back to automatic.

To scale **one** monitor, focus it and use `SUPER + SHIFT + ALT + = / - / 0` (or
Control center → Displays → Scale). It works for any monitor, however many are
connected, and is saved by the monitor's description (it comes back when that
monitor is plugged in again). Only scales that give whole pixels on that screen
are used, and the monitors next to it are moved so there is no gap or overlap.
`0` returns that monitor to the global default. From the shell:
`displays.sh scale <monitor|focused> up|down|reset|<value>`.

## Laptop lid

`scripts/lid.sh` handles the lid:

- closed with an external monitor: only the laptop panel turns off (clamshell);
- closed with no external monitor: systemd suspends the laptop;
- opened: the panel comes back (a `hyprctl reload` re-enables a disabled monitor).

`lid.sh check` runs at login and acts only when the lid is physically closed.

## External brightness

`XF86MonBrightness*` changes the focused monitor: the laptop panel through
`brightnessctl`, an external monitor through DDC/CI (`ddcutil`). Scrolling over
the battery module on the bar does the same for the monitor under the cursor.

## Power: refresh rate

`scripts/power.sh` runs at login. On battery the laptop panel drops to 60 Hz
and the `power-saver` profile is applied; on AC it goes back to 165 Hz and the
profile you had before.
