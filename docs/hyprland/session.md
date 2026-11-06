# Session: login, lock, idle, power

## Login

SDDM with the `hypr-setup` theme. The greeter mirrors the lock-screen wallpaper
and colors (`scripts/sddm-sync.sh`). Hyprland starts from there and launches the
background helpers listed at the bottom of `hyprland.lua` (bar, notifications,
wallpaper, battery and health watchers, audio follow, power).

## Lock screen

`SUPER + Esc` (or the power menu) runs `loginctl lock-session`, which calls
`scripts/lock.sh`: the Quickshell lock screen (`quickshell/lock.qml`) with the
animated wallpaper, your profile picture (`~/.face`, set with `scripts/avatar.sh`),
clock, now-playing music and battery. If Quickshell fails, `hyprlock` is the
fallback (`hyprlock.conf`).

## Idle (hypridle.conf)

| After | Action |
| --- | --- |
| 4 min | Dim the screen |
| 5 min | Lock |
| 5.5 min | Screen off (DPMS) |
| 30 min | Suspend |

## Power menu

`SUPER + X` (or the bar button): lock, reload Hyprland, suspend, log out, reboot,
shut down (`scripts/powermenu.sh`). *Reload Hyprland* runs `hyprctl reload`: the
config is re-read, nothing is closed, and a notification tells whether it loaded
cleanly or lists the config errors.

## Watchers (started at login)

- `battery-watch.sh`: warnings at 15 % and 8 %, auto-suspend at 4 % when still on
  battery.
- `health-watch.sh`: hot CPU or SSD, SMART failures, SSD wear, full disk.
- `audio-follow.sh`: a connecting Bluetooth headset becomes the default output
  so the bar and volume keys control it.
- `power.sh`: AC/battery profile switching.
