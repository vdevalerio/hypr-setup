# hypr-setup — notes for Claude

Arch Linux + Hyprland 0.56 desktop, fully reproducible: `install.sh` + `dotfiles/` mirror of `~`.
Machine: Ryzen 7 7735HS laptop (Radeon 680M iGPU + RTX 4050 dGPU), ABNT2 keyboard, eDP-1 + optional Dell on HDMI-A-2 (NVIDIA card).
Everything in this repo is written in **English** (code, comments, docs, UI strings, commit messages).

## Workflow
- The **live files in `~/.config` are the source of truth.** Edit them, test live, then `./install.sh save` (copies the MANAGED list into `dotfiles/`), commit, `git push` (private GitHub `vdevalerio/hypr-setup`, ssh).
- `install.sh` subcommands: `all` (default) · `dotfiles` · `nvim` · `save` · `data` · `extras` · `boot` · `sddm`. Anything needing sudo is run **by the user** (`! ./install.sh <cmd>`); sudo asks for a password.
- New config paths must be added to `MANAGED` (and generated/personal files to `SAVE_EXCLUDE`). Personal files (own wallpapers, `~/.face`) are never synced; default wallpapers are deploy-only.
- Test a full install in the VM: `test/vm.sh` (QEMU/KVM, ssh `localhost:2222`, user tester/tester, files in `~/VMs/hypr-setup-test`). Screenshot the VM by `grim`-ing the qemu window geometry from `hyprctl clients -j`.

## Architecture
- Hyprland config is **Lua** (`hyprland.lua`, `binds.lua`, `rules.lua`, `workspaces.lua`, `monitors.lua`, `colors.lua`), not hyprlang. Check API against `/usr/share/hypr/stubs/hl.meta.lua`; dispatch from the shell with `hyprctl dispatch 'hl.dsp.…'`. Validate with `hyprctl configerrors`.
- Per-monitor workspaces: internal panel 1–10, next monitors 11–20, 21–30 (ordered internal-first, then connector name). 1–5 are persistent.
- Colors: `themes/theme.py` (fixed palettes in `themes/palettes/*.txt` or `auto` k-means from the wallpaper) writes every color file (Hyprland, hyprlock, waybar, swaync, rofi, kitty, GTK, qt6ct, btop, fcitx5, Quickshell `colors.json`, SDDM). Accents use the mauve→blue **gradient** everywhere.
- Sizes: `scripts/look.sh` (font %, gaps, scale; state in `look.conf`) generates `font.css`/`font.rasi`/`font.conf` — never put font sizes in style files. `look.sh gaps` also sets Waybar margins (= gaps_out).
- Generated files carry an "AUTO-GENERATED … do not edit" header: change the generator, then regenerate.
- Waybar (AUR `waybar-git` until 0.16) runs under `scripts/bar.sh` (supervisor). Islands: left, window, clock, media, tray drawer, monitor (`scripts/sysmon.sh`), status, actions. Reload config with `pkill -USR2 -x waybar` (CSS reloads by itself).
- Quickshell: lock screen (`quickshell/lock.qml`, via `scripts/lock.sh`, hyprlock fallback) and workspace overview (`overview.qml` + `OverviewScreen.qml`, resident, toggled by `scripts/overview.sh` over IPC).
- dGPU power: everything long-running is wrapped in `scripts/igpu.sh` so only Hyprland holds `/dev/nvidia*`.

## Gotchas (learned the hard way)
- **Never start session daemons from Claude's shell** (waybar, bar.sh, mpvpaper, quickshell…): they outlive logout with a stale `HYPRLAND_INSTANCE_SIGNATURE`. Use `hyprctl dispatch 'hl.dsp.exec_cmd("…")'`.
- `pkill -f <pattern>` matches Claude's own shell → use the bracket trick (`pkill -f '[q]s -p …'`). `pkill rofi` matches power-profiles-daemon → `pkill -x rofi`.
- Waybar on-click commands get SIGTTOU-frozen (session on tty1) → wrap in `setsid -f`. `on-click` on `hyprland/workspaces` never fires. `{icon}`/format-icons don't work on custom modules. The built-in `mpris` module segfaults → `custom/media`.
- Rofi 2.0: no `@references` inside `linear-gradient()` (breaks every menu); test theme edits by opening a menu and screenshotting.
- Private-use Nerd glyphs (U+E000–F8FF) written by the model come out empty → use JSON/QML escapes or Material Design glyphs (U+F0000+); check bytes with `od`.
- Quickshell: Hyprland ignores focus dispatches while a layer holds Exclusive keyboard focus → close first, dispatch ~40 ms later. `Hyprland.dispatch()` takes the Lua expression. `lastIpcObject` updates only via `refreshToplevels()`. Icons need `//@ pragma IconTheme Papirus-Dark`. `sed -i` on QML breaks the live-reload watcher → restart the instance.
- Hyprland ignores keybinds coming from `wtype` (virtual keyboard): test scripts directly.
- GRUB rejects palette PNGs → force `PNG24:`/`PNG32:`. GRUB 9-slice borders are drawn around the item. `grub-mkconfig` sorts kernels by name → `GRUB_TOP_LEVEL` keeps `linux` default over `linux-lts`.
- SDDM greeter is X11 and NVIDIA is only a GPU screen → `system/sddm/Xsetup` (reverse PRIME, mirrored outputs). Test with `sddm-greeter-qt6 --test-mode --theme <dir>` and close it right away (it grabs the keyboard). `pkill sddm-greeter` (name > 15 chars for `-x`).
- mpvpaper: one per output with `-p` only (`-a FULL` pauses all outputs). `brightnessctl` needs `-e4` for set and get. `hostname` isn't installed → `uname -n`. Arch `nftables.service` shows inactive even when loaded (oneshot) → restart, not reload.
- Lid: re-enabling a disabled monitor needs `hyprctl reload`; `lid.sh check` must act only when the lid is physically closed.
- Mason in headless `install.sh`: LazyVim may already be installing a package → never `p:install()` one that `is_installing()`.
- Screenshots for self-checks: crop/resize before reading (`magick … -crop … -resize 50%`) — full 1920px images are expensive.
