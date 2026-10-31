# hypr-setup

A complete Arch Linux + **Hyprland** setup, from a fresh system install to a ready desktop:
one script (`install.sh`) and the configs (`dotfiles/`). Built to be used **keyboard-only**,
but with everything clickable for mouse users.

- **Look:** colors generated from the wallpaper (image, GIF or video), applied across the whole system.
  Or a fixed theme: Catppuccin, Tokyo Night, Gruvbox, Nord, Rosé Pine, Everforest, Kanagawa, Dracula.
- **Live adjustments:** font size, window gaps and display scale via shortcuts,
  plus a control center with everything else (the bar only shows the essentials).
- **Terminal:** transparent kitty + zsh with Starship, autosuggestions, fzf, atuin (history), direnv and mise.
- **Editor:** Neovim (LazyVim) as a Python / data science IDE, with Jupyter-style cells.
- **Files:** yazi. **System:** in English, ABNT2 keyboard.
- **Keyboard languages:** Portuguese (ABNT2), English, Russian and Japanese (fcitx5 + Mozc).

---

## Installation

**Prerequisites:** Arch Linux installed (e.g. `archinstall`, *minimal* profile), a user with
`sudo`, a working internet connection and `git` installed.

```bash
sudo pacman -S --needed git
git clone <your-repository-url> ~/Projects/Personal/hypr-setup   # or copy the folder over on a USB stick
cd ~/Projects/Personal/hypr-setup
bash install.sh        # asks for the sudo password once
sudo reboot
```

On the login screen, choose the **Hyprland** session. On first login the animated wallpaper is applied
and the colors are generated. **SUPER + F1** shows all shortcuts.

If you already have configs in your home, the script moves the ones that differ to
`~/.config-backup/<date>/` before copying the new ones. It is safe to run it again.

### Script commands

| Command | What it does |
|---|---|
| `./install.sh` | Full install: packages, drivers, system, configs, shell and Neovim |
| `./install.sh dotfiles` | Only copies the configs from `dotfiles/` to your home (no sudo) |
| `./install.sh nvim` | Only sets up Neovim (plugins, parsers, language servers) |
| `./install.sh save` | Copies the **current** configs from your home into `dotfiles/` (use after customizing) |
| `./install.sh sddm` | (Re)installs the login screen theme (asks for sudo) |
| `./install.sh extras` | Firewall, zram, automatic maintenance, rollback snapshots, disk health, VPN, lid and battery limit (asks for sudo) |
| `./install.sh gaming` | Steam, GameMode and MangoHud; enables multilib (asks for sudo, not part of the full install) |
| `./install.sh wipe` | **Destructive** factory reset back to a bare Arch: removes all packages outside the base set, the user and its home, history, logs and caches (`--dry-run` shows the plan; asks for the hostname; needs a root password). Tested in the VM only |

### What to adjust before running

At the top of `install.sh`:

- **Language and keyboard:** `SYS_LANG`, `CONSOLE_KEYMAP`, `XKB_LAYOUT` and `XKB_MODEL`.
  The keyboard inside Hyprland is set in `dotfiles/.config/hypr/hyprland.lua` (`kb_layout`, `kb_model`).
- **Personal apps:** `PERSONAL_PKGS` and `PERSONAL_AUR` (Brave, KeePassXC, Claude Desktop, tmux…).
  SUPER + B opens Brave; if you remove Brave, change `browser` in `dotfiles/.config/hypr/binds.lua`.

### Private settings

Anything personal stays out of the repo. Copy `private.env.example` to
`private/private.env` (the whole `private/` folder is git-ignored) and edit it:

- `GIT_NAME` / `GIT_EMAIL`: your git identity, written to `~/.config/git/local`;
- `BACKUP_EXTRA_PATHS`: extra folders for `backup`.

`private/private.spell.add` is a fourth Neovim spelling list (`4zg`) for names you do not
want to publish (clients, companies). `./install.sh` deploys both to `~/.config/hypr-setup/`
(without a `private.env` it copies the example and warns), and `./install.sh save` copies
them back to `private/`.

### Hardware

The script detects the hardware on its own:

- **CPU:** installs the right microcode (AMD or Intel).
- **GPU:** AMD, Intel or NVIDIA. For NVIDIA it uses `nvidia-open`, which needs a Turing card
  (GTX 16xx / RTX 20xx) or newer. On kernels other than the default `linux`, it uses the `-dkms` version.
- **Hybrid laptop** (integrated + NVIDIA): the desktop runs on the integrated GPU to save battery.
  To use the NVIDIA GPU for an app, launch it with `prime-run <app>`. It also enables proper NVIDIA suspend and
  RTD3: when idle, the NVIDIA GPU powers itself off (`cat /sys/bus/pci/devices/<id>/power/runtime_status` →
  `suspended`). With a monitor plugged into its output (this laptop's HDMI) it stays on — that's expected.

Tested on: Ryzen 7 7735HS + Radeon 680M + RTX 4050 (laptop), Hyprland 0.56.

---

## What's installed

| Role | Program |
|---|---|
| Compositor | Hyprland 0.56 (config in **Lua**) |
| Bar | Waybar (+ control center in Rofi) |
| Launcher, emoji, calculator, clipboard, menus | Rofi |
| Notifications | SwayNC |
| Keyboard languages | fcitx5 (+ Mozc for Japanese) |
| Screen lock / idle | Quickshell (lock.qml, hyprlock as fallback) / hypridle |
| Night light | hyprsunset |
| Wallpaper | awww (images and GIFs) and mpvpaper (videos) |
| Color themes (automatic from the wallpaper, or fixed) | theme.py (custom) |
| Terminal | kitty |
| Shell | zsh + Starship, fzf, zoxide, lsd, bat |
| Editor | Neovim + LazyVim |
| Files | yazi |
| Screenshots | grim + slurp + satty |
| Login | SDDM (custom theme, same as the lock screen) |
| Audio / network / bluetooth | PipeWire / NetworkManager / Blueman |

---

## Shortcuts

`SUPER` = the Windows key. **SUPER + F1** opens this list, searchable, inside the system.

### Apps and system
| Shortcut | Action |
|---|---|
| SUPER + Enter | Terminal |
| SUPER + Space (or D) | App menu |
| SUPER + SHIFT + Space | Run command |
| SUPER + Tab | Workspace overview (live thumbnails) |
| SUPER + CTRL + T | To-do list (Rofi) |
| ALT + Tab | Window list |
| SUPER + E / B | Files (yazi) / browser |
| SUPER + V | Clipboard history |
| SUPER + ; / = | Emoji / calculator |
| SUPER + N / SHIFT + N | Notification center / clear |
| SUPER + SHIFT + C | Color picker (copies the color) |
| SUPER + A | Control center |
| SUPER + SHIFT + B | Show/hide the bar |
| SUPER + Esc | Lock screen |
| SUPER + X | Power menu (lock, reload Hyprland, suspend, log out, reboot, shut down) |
| SUPER + CTRL + Q | Exit Hyprland |

### Appearance (live, saved to `~/.config/hypr/look.conf`)
| Shortcut | Action |
|---|---|
| SUPER + ALT + `=` / `-` / `0` | Larger / smaller / default fonts |
| SUPER + CTRL + `=` / `-` / `0` | Larger / smaller / default window gaps (can be held down) |
| SUPER + CTRL + ALT + `=` / `-` / `0` | Larger / smaller / automatic display scale of **all** monitors |
| SUPER + SHIFT + ALT + `=` / `-` / `0` | Larger / smaller / default scale of the **focused monitor only** |

### Keyboard language
| Shortcut | Action |
|---|---|
| SUPER + CTRL + Space | Next language (+ SHIFT: previous) |
| SUPER + CTRL + 1 / 2 / 3 / 4 | Portuguese / English / Russian / Japanese |

### Protection and maintenance

- **Updating the system:** the `update` command (or control center → Tools → System update). It shows the
  Arch news since the last update (sometimes they require a manual step), updates packages and the AUR, and
  then warns about `.pacnew` files, new firmware, orphaned packages and whether a reboot is needed.
  Before upgrading it takes a rollback snapshot (below). When updates are pending, `󰚰 N` shows on the
  bar (checked every 30 minutes; click to update; hover for the list).
- **Backup:** restic, encrypted and incremental, to **Google Drive** (`Backups/` folder), every day
  (or as soon as you power on, if it missed the time). It copies Documents, Projects, Desktop, Pictures, Music, SSH keys,
  GPG and the keyring, excluding `node_modules`, `.venv` and caches. Keeps 7 daily, 4 weekly and 6 monthly.
  - First time: `backup setup` (authorizes Drive in the browser and creates the password), then
    `backup drive-client`: registers **your own** Google credential (step by step in the command itself).
    The shared rclone credential is being deprecated and gives a "Quota exceeded" error.
  - **Keep the password** (`~/.config/restic/password`) in KeePassXC: without it there is no way to recover anything.
  - `backup run` (now), `backup status`, `backup list`, `backup restore latest ~/Restored`.
- **Firewall** (nftables): blocks incoming connections and allows outgoing ones. Rules in
  `system/etc/nftables.conf`, which also explains how to open a port.
- **Automatic:** SSD TRIM (weekly), pacman cache cleanup (keeps the last 3 versions) and
  firmware check (fwupd).
- **Before every update** pacman saves the package list (with versions) and a copy of `/etc` in
  `/var/backups/hypr-setup/` (the last 10). To roll a package back: `sudo pacman -U
  /var/cache/pacman/pkg/<package>-<version>...`.
- **Rollback snapshots:** Timeshift (rsync mode, since the disk is ext4) copies `/` — not `/home`, which
  `backup` covers — to `/timeshift` before every `update`; the last 5 are kept. Hard links make all but the
  first one fast and small. A copy of `/boot` (a separate partition) travels inside each snapshot.
  - `sudo hypr-setup-rollback create` (now) · `list` · `restore [name]` (asks to confirm, restores `/` and
    `/boot`, then reboot). If the system doesn't boot at all, boot a live USB, mount the root
    partition and run `timeshift --restore` from there.
  - Package version rollback is still possible with the pacman cache (see above).
- **Hardware warnings** (notifications): CPU hot for 3+ minutes (90 °C), SSD at 70 °C / 80 °C, SMART failing or
  with errors, SSD wear at 90 %, `/` at 90 % / 95 % full. SMART is read as root every 6 hours
  (`hypr-setup-smart.timer`) because `smartctl` needs it. The NVIDIA GPU is never queried: that would wake it.
- **Fallback kernel** (`linux-lts`): if a kernel update breaks boot or NVIDIA, pick
  *Advanced options → linux-lts* in GRUB. NVIDIA and the battery limit use DKMS and work on both.
- **Mirrors:** reflector picks the fastest ones every week (Brazil + US, in
  `system/etc/xdg/reflector/reflector.conf`).
- **zram:** swap compressed in memory (half of the RAM), used before disk swap. Makes the system feel
  smoother when memory gets tight.

## VPN and games

- **VPN:** WireGuard (through NetworkManager) and Tailscale. Control center → Tools → VPN lists your
  tunnels; click one to connect or disconnect, or import a `.conf` (`nmcli` stores it, so it also shows up
  in `nm-connection-editor`). `󰖂` shows on the bar while a VPN is connected (click to manage). Tailscale signs
  in once, in the browser. The firewall still blocks **incoming** connections on the VPN interface too.
  The **Pritunl** client (`pritunl-client-bin`, prebuilt) is installed too: its `pritunl-client.service` daemon
  is enabled by `install.sh`; open "Pritunl" from the launcher and import your profile (URI or `.tar`).
  Don't install `pritunl-git`: that is the VPN *server*, not the client.
- **Games** (`./install.sh gaming`): Steam runs on the integrated GPU like everything else, so the NVIDIA GPU
  stays off. For a game, set its Steam launch option to `game %command%` (right click → Properties):
  it runs on the NVIDIA GPU with GameMode (performance power profile while playing) and MangoHud
  (FPS overlay, `Right Shift + F12` toggles it). Outside Steam: `game ./some-game`.

## Laptop

- **Volume, mute, microphone, brightness and Caps Lock keys** show a quick notification with the level
  (`scripts/osd.sh`).
- **Plugged in vs. battery** (`scripts/power.sh`): when unplugged, the laptop screen drops to 60 Hz and the power
  profile to *power saver*; when plugged back in, the screen returns to 165 Hz and to the profile you were using. To pin a
  refresh rate, set the monitor's `mode=` in Displays. Fullscreen games and videos use adaptive sync (VRR).
- **GPU video in Brave** (VA-API): YouTube and meetings use less battery. Check at
  `brave://gpu` ("Video Decode: Hardware accelerated") or with `vainfo`.
- **Boot:** the GRUB menu is hidden (boot doesn't wait); hold **Esc** or **Shift** at power-on to
  see the menu and pick `linux-lts`.
- **Low battery:** warning at 15%, alert at 8% and automatic suspend at 4% (if still on battery).
- **Lid closed with an external monitor:** turns off only the laptop screen and you keep working on the monitor; when opened,
  it comes back with your workspaces. Without an external monitor, closing the lid suspends (and locks).
- **Charge limit at 80%** (Acer, `acer-wmi-battery` module): extends battery lifespan. To
  charge to 100% for a trip: `echo 0 | sudo tee /sys/bus/wmi/drivers/acer-wmi-battery/health_mode`
  (goes back to 80% on the next boot, or with `echo 1`).

## Git, SSH and terminal

- **Git** (`~/.config/git/config`): `main` branch, `pull` with rebase, `push` creates the upstream by itself,
  diffs with **delta** (theme colors), conflicts showing the original chunk (zdiff3) and commits **signed with the
  SSH key**. For GitHub to show "Verified", upload the key as a signing key:
  `gh auth refresh -s admin:ssh_signing_key && gh ssh-key add ~/.ssh/id_ed25519.pub --type signing`.
  Settings for this machine only (e.g. a different email in a work folder) go in `~/.config/git/local`:
  ```ini
  [includeIf "gitdir:~/Projects/Work/"]
      path = ~/.config/git/work
  ```
- **SSH agent** from gnome-keyring: loads the keys in `~/.ssh` and remembers their passphrase (logging in unlocks the
  keyring). Setting a passphrase on the key is recommended: `ssh-keygen -p -f ~/.ssh/id_ed25519`.
- **Ctrl+R** = atuin: searchable history with directory, duration and whether it failed; inside it, Ctrl+R again
  filters by session/directory. Local only (no account). ↑ still searches by what you've already typed.
- **direnv:** an `.envrc` in the project folder loads variables on entry and unloads them on exit
  (`direnv allow` the first time). **mise:** per-project Node/Python/Go… versions (`mise use node@22`).
- **Terminal apps in the theme:** btop (theme generated by `theme.py`, with gradients), lazygit and yazi (terminal
  colors, they follow any theme on their own). The terminal opens with **fastfetch**; to turn it off, put
  `export FASTFETCH_ON_START=0` at the top of `~/.zshrc`.
- **To-do list:** `todo add "text"`, `todo` (list), `todo done 2`, `todo rm 2`, `todo undo 1`, `todo clear`
  (`scripts/todo.sh`). Plain todo.txt format in `~/.local/share/todo/todo.txt` (included in the backup). The checklist
  icon on the bar shows the pending count and the tasks in its tooltip; click it, or press SUPER + CTRL + T, for a
  Rofi list: pick a task to finish/reopen it, type text and Enter to add one, Esc to close.
- **tmux sessions survive a reboot, fully automatic:** Hyprland starts the tmux server at login (`hyprland.lua`),
  and tmux-continuum saves every session (windows, panes, folders, pane text) every 15 minutes and restores them
  when that server starts. kitty opens every terminal inside tmux (`shell` in `kitty.conf` →
  `scripts/tmux-start.sh`): it attaches to a restored session nobody is using, or opens a new one when all are
  in use (plain zsh if tmux is missing; apps started with `kitty -e` are untouched). Manual save/restore:
  `prefix + Ctrl+s` / `prefix + Ctrl+r` (prefix = `Ctrl+a`). Running programs are not resumed, only their windows/folders/text. Plugins
  (tmux-resurrect, tmux-continuum) are cloned by `./install.sh dotfiles` into `~/.config/tmux/plugins/` (not synced);
  saves live in `~/.local/share/tmux/resurrect/`.
- `help <command>` (tldr) shows short examples; `locate <name>` finds files across the whole disk instantly.
- **USB sticks/external drives** mount automatically at `/run/media/$USER/` (udiskie) with a notification.

## Recording, screen text and meetings

- **Screen recording:** SUPER + ALT + R (the focused monitor, with system sound) or SUPER + ALT + SHIFT + R
  (an area). In control center → Tools there is also "with microphone". While recording, `󰑋 0:12`
  shows in red on the bar (click to stop). Videos in `~/Videos/Recordings`.
- **Copy text from the screen (OCR):** SUPER + CTRL + S, select the area and the text goes to the
  clipboard. Portuguese and English; Japanese and Russian via control center → Tools.
- **Sharing your screen in meetings** (Meet, Teams, Zoom in the browser): the browser opens a small window to
  choose the screen, the window or an area. Test before an important meeting at
  https://webrtc.github.io/samples/src/content/getusermedia/getdisplaymedia/

## Login screen

The login screen (SDDM) looks the same as the lock screen: blurred wallpaper (animated, if the
wallpaper is a video or GIF), clock, greeting,
profile photo and password field on the glass card, with the wallpaper's colors. At the bottom: session (click
to change), keyboard layout and suspend, reboot and shut down buttons.

- Background, colors and photo automatically follow changes to the wallpaper, color mode and photo
  (`~/.config/hypr/scripts/sddm-sync.sh`, called by `wallpaper.sh`, by `avatar.sh` and at login).
  SDDM can't read your home, so those files go to `/usr/share/sddm/themes/hypr-setup/dynamic/`,
  a folder owned by your user.
- It appears **mirrored on all connected monitors** (what you type shows on all of them). On a
  hybrid laptop, monitors plugged into the NVIDIA GPU are enabled by `system/sddm/Xsetup` ("reverse PRIME").
  Mirroring only applies at login; the session uses the Displays arrangement.
- **Animated background:** when the wallpaper is a video or GIF, `sddm-sync.sh` generates an already blurred
  and darkened version (960×540, up to 60 s) in `dynamic/background.mp4`. It takes a few seconds, in the background,
  on every wallpaper change.
- The theme lives in `system/sddm/hypr-setup/` (QML). After editing, run `./install.sh sddm`.
  To test without leaving the session: `sddm-greeter-qt6 --test-mode --theme system/sddm/hypr-setup`.

## Wallpaper and colors
| Shortcut | Action |
|---|---|
| SUPER + SHIFT + W | Pick a wallpaper (with thumbnails) |
| SUPER + CTRL + W | Random wallpaper |
| SUPER + SHIFT + T | Color theme: automatic (from the wallpaper) or one of the fixed themes |

### Windows
| Shortcut | Action |
|---|---|
| SUPER + Q | Close |
| SUPER + F / M | Fullscreen / maximize |
| SUPER + T | Floating ↔ tiled |
| SUPER + C / P | Center / pin on all workspaces |
| SUPER + Y | Toggle horizontal/vertical split |
| SUPER + G, ALT + Tab, ALT + SHIFT + Tab | Group into tabs, next/previous tab |
| SUPER + arrows or `h j k l` | Move focus |
| SUPER + SHIFT + arrows/hjkl | Move the window |
| SUPER + CTRL + arrows/hjkl | Resize (or SUPER + R, arrows, Esc) |

### Workspaces
| Shortcut | Action |
|---|---|
| SUPER + 1…0 | Go to workspace (on the focused monitor) |
| SUPER + SHIFT + 1…0 | Move the window to workspace (on the focused monitor) |
| SUPER + , / . | Previous / next workspace (on the focused monitor) |
| SUPER + ' | Back to the last workspace |
| SUPER + W | Empty workspace (on the focused monitor) |
| SUPER + O / SHIFT + O | Focus the next monitor / send the window to it |
| Brightness keys | Brightness of the focused monitor (laptop or external) |
| SUPER + S / ALT + S | Scratchpad: show / send window |

### Screenshots, recording and screen text
| Shortcut | Action |
|---|---|
| SUPER + ALT + R | Record the screen (the focused monitor); again to stop |
| SUPER + ALT + SHIFT + R | Record an area |
| SUPER + CTRL + S | Copy the text from an area of the screen (OCR) |
| Print (or SUPER + SHIFT + S) | Area, copied and saved to `~/Pictures/Screenshots` |
| SHIFT + Print | All monitors |
| CTRL + Print | Focused monitor only |
| SUPER + Print | Area + editor (satty) |

### Mouse
- **Bar:** everything is clickable.
  - Arch logo: apps (right-click: shortcuts). Clock: calendar (right-click: full date).
  - Workspaces: the ones with windows get a lighter number and a small underline. Clicking the window
    title (next to them) lists the windows of each workspace (Enter jumps to the window).
  - Music (shows up when something is playing): click = play/pause, right-click = next, scroll = previous/next.
  - `󰅁` on the right: hover to see background apps (Wi-Fi, Bluetooth, keyboard language…).
  - Monitoring: CPU, GPU, temperature, RAM and disk; click = btop.
  - Volume: click = mute, right-click = mixer, scroll = volume.
  - Battery: scroll = brightness of that bar's monitor.
  - `󰂚` notifications (right-click: do not disturb). `󰒓` control center (right-click: appearance). `󰐥` power.
- **Windows:** SUPER + dragging with the left button moves, with the right button resizes.
  You can also drag the edges.
- **Workspaces:** SUPER + scroll switches; on the touchpad, 3 fingers horizontally.

---

## Multiple monitors

- **Each monitor has its own workspaces 1–10.** SUPER + 1…0 and each monitor's bar apply only to that monitor.
  Internally, the laptop screen uses workspaces 1–10 and the other monitors 11–20, 21–30 (in connector
  order, not position: rearranging the screens doesn't scramble the workspaces). The bar shows 1–10 on
  all of them. Workspaces 1–5 of each monitor are always shown, even when empty.
- **Connecting or disconnecting** a monitor rearranges the workspaces and restarts the animated wallpaper by itself.
- SUPER + O focuses the next monitor and SUPER + SHIFT + O sends the window to it.
- **Configuring the screens:** control center → **Displays**. For each monitor: position (left of,
  right of, above or below another), resolution and refresh rate, scale, rotation, mirroring another monitor,
  turning off/on, back to automatic. Applies immediately and is saved to `~/.config/hypr/monitors.conf`,
  by the monitor's description (still applies if you switch ports). With no adjustment, everything is automatic
  (the new monitor goes to the right) and the scale follows SUPER + CTRL + ALT + `=` / `-` (all monitors).
- **Scale per monitor:** SUPER + SHIFT + ALT + `=` / `-` / `0` changes only the focused monitor (any monitor, however
  many are connected; `0` returns it to the default). It is saved by the monitor's description in `monitors.conf`, so it
  comes back when that monitor is reconnected. Monitors next to it are repositioned so no gap or overlap appears, and
  only scales that give whole pixels on that screen are offered. Same thing in control center → Displays → Scale.
  Script: `displays.sh scale <monitor|focused> up|down|reset|<value>`.
- **Independent brightness:** the brightness keys change the focused monitor; the mouse wheel on the battery
  changes that bar's monitor; control center → Brightness lists them all.
  External monitors use **DDC/CI**: enable the "DDC/CI" option in the monitor's own menu. Test with
  `ddcutil detect`. Monitors that don't support it keep brightness on their own buttons.
- Code: `~/.config/hypr/workspaces.lua`, `monitors.lua`, `scripts/displays.sh` and `scripts/brightness.sh`.

## Bar and control center

The bar shows only the essentials, in "islands": workspaces and active window on the left; clock and music in the
center; tray (Wi-Fi, Bluetooth, language and other background apps), monitoring, volume, battery, notifications, control center and power on the right.

The **monitoring** island shows CPU usage, the usage of the busiest GPU, CPU temperature, RAM and
the `/` disk. Each item turns yellow or red under load or heat. The tooltip gives the details of each
card (usage, temperature, VRAM, power draw) and of all sensors, and clicking opens **btop**. The NVIDIA GPU
is only queried if it is already awake, so the reading doesn't pull the card out of power-saving mode. Script:
`~/.config/hypr/scripts/sysmon.sh` (`gpu`, `temp`, `top`).

The `󰒓` button (or **SUPER + A**) opens the **control center**, a panel below the bar with:

- **Appearance:** fonts, window gaps, display scale, wallpaper, color mode, profile photo,
  show/hide the bar.
- **Do not disturb**, **Keep screen awake** (pauses the automatic lock) and **Night light** (warmer screen).
- **Brightness** (per monitor) and **Displays** (position, resolution, scale, rotation, mirroring, on/off).
- **Power profile**, **Wi-Fi**, **Bluetooth** (on/off and pairing), **Audio mixer**
  and **Keyboard** (language and fcitx5 settings).
- **Tools:** screenshots, color picker, clipboard, emoji, calculator, system monitor and shortcuts.

Navigate with the arrows or type to filter. Adjustments (larger font, brightness, on/off…) keep
the panel open: press Enter again to repeat. When something deviates from normal (screen always on,
night light, a power profile other than *balanced*, Bluetooth connected), its icon shows up
next to the `󰒓` on the bar.

Script: `~/.config/hypr/scripts/controlcenter.sh` (`status`, or the name of a submenu to open it directly).

## Fonts, window gaps and scale

- **Fonts** (SUPER + ALT + `=` / `-`): in 10% steps, from 50% to 200%. Changes the bar, menus, notifications,
  terminals (including open ones) and GTK and Qt apps (already-open ones update when reopened).
- **Window gaps** (SUPER + CTRL + `=` / `-`): the gap to the screen edge follows.
- **Display scale** (SUPER + CTRL + ALT + `=` / `-`, all monitors; one monitor: SUPER + SHIFT + ALT + `=` / `-`): increases or decreases **everything** (fonts, icons,
  windows). On this laptop (1920×1080) the automatic scale is 1.5. If everything looks big, try
  1.25 or 1.2. `0` goes back to automatic.
- The values are stored in `~/.config/hypr/look.conf` and persist across reboots (`hyprland.lua`
  reads that file). Script: `~/.config/hypr/scripts/look.sh font|gaps|scale up|down|reset`.
- The sizes live in files generated by the script (don't edit by hand): `waybar/font.css`,
  `swaync/font.css`, `rofi/font.rasi` and `kitty/font.conf`. The base sizes (at 100%) are in `look.sh`.

## Keyboard languages

Four languages, managed by **fcitx5**: Portuguese (ABNT2), English (`us`), Russian (`ru`) and Japanese (Mozc).
The language applies to all apps at once, and the fcitx5 icon in the tray (the bar's `󰅁` menu) shows the current one.

- **Switching:** SUPER + CTRL + Space, SUPER + CTRL + 1…4, click on the bar or control center → Keyboard.
- **System shortcuts** stay on the ABNT2 layout whatever the language (SUPER + Q closes even in Russian).
  Ctrl+Space is left free (Neovim uses it).
- **Japanese:** type in romaji (`nihongo`) and it becomes hiragana. **Space** converts to kanji
  (Space again or the arrows pick), **Enter** confirms. F7 = katakana, F10 = romaji. Esc cancels.
- **Password and lock screen:** always ABNT2 (fcitx5 doesn't act on password fields).
- **Changing the list or order:** control center → Keyboard → *Input method settings* (`fcitx5-configtool`),
  or edit `~/.config/fcitx5/profile`. English uses the `us` layout: on an ABNT2 keyboard some symbols move
  around (e.g. `;` ends up on the `ç` key). If you prefer, switch to `keyboard-us-intl` or another.
- **Apps:** GTK, Qt, kitty and X11 apps work out of the box. Brave and Claude Desktop need the flags in
  `~/.config/brave-flags.conf` and `~/.config/claude-desktop-flags.conf` (already included). For another
  Electron/Chromium app, launch it with `--enable-wayland-ime --wayland-text-input-version=3`.
- The Japanese candidate window follows the wallpaper colors and the font size from `look.sh`.
- **Problems:** `fcitx5-diagnose` shows what's missing. Script: `~/.config/hypr/scripts/keyboard.sh`.

## Workspace overview

**SUPER + Tab** shows each monitor's workspaces in a grid: the fixed ones (1–5), the occupied ones and a `+` for
a new workspace. Windows appear at their real position and size, as live thumbnails, including
those on hidden workspaces. Idle windows (that don't redraw) show the app icon.

- **Mouse:** click a workspace to go to it and a window to focus it. **Drag a window**
  to another workspace (or to the `+`) to move it without leaving the overview.
- **Keyboard:** arrows or Tab choose, Enter goes, 1–9/0 jump straight to the workspace. **Typing filters**
  windows by title or app (Enter focuses the first match). Esc clears the filter and then closes.
  SUPER + Tab again, or a click outside the cards, also close it.
- Built with Quickshell (`~/.config/quickshell/overview.qml` + `OverviewScreen.qml`), using the theme colors.
  It stays open in the background, on the integrated GPU, to open instantly. Script:
  `~/.config/hypr/scripts/overview.sh [toggle|open|close|start]` (starts the process if it has died).

## Lock screen

**SUPER + Esc**, or automatically after 5 min idle. Shows the current wallpaper blurred, clock, greeting,
the password field on a glass card and, at the bottom, the music playing, the keyboard layout and the battery.

- **Profile photo** in place of the icon: control center → Appearance → **Photo**. Shows the most recent
  images from Pictures, Downloads and Desktop (or *Browse…* to pick any file through yazi).
  The photo is cropped to a square (portrait ones closer to the top, where the face usually is) and saved to
  `~/.face`. On the same screen you can remove it. Script: `~/.config/hypr/scripts/avatar.sh pick|browse|set|remove`.
- The background is a frame of the wallpaper, saved to `~/.cache/wallpaper/lock.png` on every change.
- Esc or Ctrl+U clear the password. With Caps Lock on, the field's border turns yellow.

## Wallpaper and colors

- Put files in `~/Pictures/Wallpapers`: png, jpg, webp, gif, mp4, webm, mkv or mov.
  The default is `aurora.mp4` (animated, 20 s loop).
- Videos pause by themselves on a monitor where they're covered (e.g. a fullscreen window), to save
  battery. Each monitor has its own process (mpvpaper), and the other one keeps animating.
- **Themes** (SUPER + SHIFT + T, or control center → Appearance → Theme):
  - **Automatic:** colors come from each wallpaper (for a video or GIF, from a frame). The dominant color
    tints the background, and the main accent (borders, active workspace, menus) is the most vivid color that
    contrasts with it: the tree's pink against the blue sky, the portal's red in the night… Accents
    stay vivid and readable on the dark background. A wallpaper without color produces muted accents. Red, green, yellow and orange
    stay fixed, to keep their meaning (errors, battery…).
  - **Fixed themes:** Catppuccin Mocha, Tokyo Night, Gruvbox, Nord, Rosé Pine, Everforest, Kanagawa and
    Dracula. The menu shows color swatches and stays open so you can keep trying them.
  - The theme changes instantly: window borders, active workspace, bar, menus, notifications, terminal,
    Neovim, lock screen, login screen, GTK apps and the Japanese input window.
  - In the wallpaper picker, **Alt+T** toggles between Automatic and the last fixed theme.
- **Creating a theme:** copy a file from `~/.config/hypr/themes/palettes/`, change the name (`# name:`)
  and the colors. It shows up in the menu on its own. `mauve` is the main accent (borders, active workspace,
  selection) and `blue` the second tone of the gradients.
- **Script:** `~/.config/hypr/scripts/wallpaper.sh` with `set <file>`, `pick`, `random`, `restore`
  and `theme auto|<theme>|toggle`. Color generator: `~/.config/hypr/themes/theme.py` (`list`, `set`, `auto`).

## Terminal (zsh)

- **Prompt:** folder, git branch and status, Python version, active `.venv` and the duration of long commands.
- **History:** ↑/↓ search by what you've already typed. **Ctrl+R** searches the history.
- **fzf:** **Ctrl+T** searches files (with preview) and **Alt+C** jumps to a folder.
- **Navigation:** `z <name>` goes to folders you've used before and `y` opens yazi (on exit, the terminal stays in that folder).
- **Listing:** `ls` / `ll` / `la` / `lt` use lsd (icons, compact grid, git status).
- **Python:** the project's `.venv` activates by itself when you enter the folder.
  `mkds <name>` creates a data project with uv: pandas, numpy, polars, scikit-learn,
  matplotlib, seaborn, ipython, ruff and pytest.
- **Transparency:** `Ctrl+Shift+A` then `M` / `L` makes the kitty background more or less opaque.

## Neovim (IDE for Python / data mining)

`<space>` shows all shortcuts.

- **Python:** basedpyright (types), ruff (lint and format on save), debugger (debugpy),
  tests (pytest) and venv picker (`<space> c v`).
- **Jupyter-style cells:** separate code with `# %%`.
  - **Shift+Enter** runs the cell in the `.venv`'s IPython and moves to the next one.
  - `]j` / `[j` navigate between cells and `<space> j a` creates a new cell.
  - `<space> j` has the rest: open/close the REPL, run line, selection or file, interrupt…
- **`.ipynb` notebooks:** open as code with `# %%` cells and save back keeping the outputs.
- **Data:** CSV/TSV open as a table (`Tab` jumps between columns) and SQL has a database browser (`<space> D`).
- **Markdown:** tables and headings are rendered inline; they stay rendered while moving the cursor in normal mode and show the real characters only in insert mode (wide cells wrap to fit the window).
- **Plots:** matplotlib's open in a floating window.
- **Look:** transparent background, with the wallpaper colors updated live.

## Files (yazi)

SUPER + E, or `y` in the terminal.

- **Navigate:** arrows or `h j k l`. `Enter` opens and `.` shows hidden files.
- **Copy and move:** `Space` selects, `y` / `x` / `p` copy / cut / paste.
- **Files:** `d` sends to the trash, `a` creates (end with `/` for a folder) and `r` renames.
- **Search:** `/` searches and `z` uses zoxide.
- **Help:** `F1` shows all shortcuts.

---

## Structure

```
hypr-setup/
├── install.sh                    # install / deploy / save
├── README.md
├── system/sddm/                  # login screen: hypr-setup/ theme (QML) and Xsetup (all monitors)
├── system/etc/                   # firewall, zram, lid, battery limit (installed to /etc)
└── dotfiles/                     # mirror of the home
    ├── .zshrc
    ├── .config/
    │   ├── hypr/                 # hyprland.lua, binds.lua, rules.lua, colors.lua (generated),
    │   │   │                     #   workspaces.lua, monitors.lua + monitors.conf (screens), look.conf,
    │   │   ├── themes/           # theme.py (colors) + palettes/ (fixed themes)
    │   │   │                     #   hyprlock, hypridle
    │   │   └── scripts/          # wallpaper, look, controlcenter, displays, brightness, keyboard,
    │   │                         #   avatar, sddm-sync, powermenu, lockinfo, screenshot, clipboard, keybinds,
    │   │                         #   update, backup, record, ocr, lid, battery-watch, bar, media
    │   ├── fcitx5/               # keyboard languages (profile), shortcuts and appearance
    │   ├── brave-flags.conf  claude-desktop-flags.conf   # IME on Wayland
    │   ├── waybar/  rofi/  swaync/  kitty/  yazi/  lsd/  starship.toml
    │   ├── nvim/                 # LazyVim + plugins/datascience.lua, colorscheme.lua
    │   └── gtk-3.0/  gtk-4.0/  user-dirs.*
    ├── .icons/default/           # cursor
    ├── .local/share/applications/yazi-kitty.desktop
    ├── .local/share/fcitx5/themes/hypr-setup/   # fcitx5 theme (generated by theme.py)
    └── Pictures/Wallpapers/      # aurora.mp4, catppuccin-mountains.png
```

## Claude Code

`./install.sh claude` installs the status line (`~/.claude/statusline.sh`) and merges `claude/settings.json` into `~/.claude/settings.json` (backup in `settings.json.bak.hypr-setup`; existing hooks and permissions are kept):

- **Model `opusplan`**: Opus while in plan mode (Shift+Tab), Sonnet for execution. Subagents default to Sonnet.
- **Context hygiene**: auto-compact at 70% of a 300k window; Bash output capped at 20k chars, MCP output at 10k tokens.
- **Status line**: model · context bar (green/yellow/red) · session cost · 5-hour plan usage · dir · branch. `/clear` before the bar turns red.
- **Fewer prompts**: read-only commands (git status/diff/log, rg, ls, hyprctl queries…) are pre-approved.
- **Waybar chip** (monitor island, 󰚩): session (clock icon, 5h) and weekly (calendar icon) plan usage while a session is open, otherwise today's tokens; the tooltip adds when each limit resets (the weekly one shows the day) plus today / 7 days by model. Click for the `ccusage` report. In the terminal: `ccu daily`, `ccu blocks --active`.

### Skill forge (self-improving skills per repository)

- `/forge-skills` explores the current repo (via the cheap `pesquisador` agent) and writes 2-4 lean skills to `<repo>/.claude/skills/` (workflow, architecture, gotchas), kept out of git through `.git/info/exclude`.
- The `friction-log.mjs` hook (tool failures and user corrections) appends short lines to `~/.claude/forge/friction/<repo>.jsonl`. No output and no model calls, so it costs no tokens.
- `/retro` clusters the new friction and proposes **diffs** to the forged skills, the repo's `CLAUDE.md`, and the `forge-skills`/`retro` skills themselves. Nothing is applied without your approval.
- Not connected to any ticket-tracking system on purpose. `install.sh claude` merges the hooks without touching existing ones.

Start `claude` inside `~/Projects/Personal/hypr-setup` when working on the desktop so `CLAUDE.md` (workflow and gotchas) and the `desktop-verifier` agent (cheap Haiku post-change checks) are loaded. Restart Claude Code after `install.sh claude`.

## Keeping it up to date (GitHub)

This folder is **self-sufficient**: with it, a freshly installed Arch machine ends up just like this one,
without copying anything else. After changing something on the system:

```bash
cd ~/Projects/Personal/hypr-setup
./install.sh save                 # brings the current configs from your home into dotfiles/
git add -A && git commit -m "tweaks" && git push
```

**What goes along:** packages (including drivers, detected on the fly), system settings
(language, keyboard, login, GPU, services), all configs in the `MANAGED` list of `install.sh`,
default apps (`mimeapps.list`), font/gaps/scale preferences and the color mode
(`~/.config/hypr/look.conf`) and the two default wallpapers.

**What doesn't (personal files):** your wallpapers, the profile photo (`~/.face`), SSH keys,
the KeePassXC database, browser profiles (use the browser's sync), the Claude login,
the Mozc dictionary and `~/.claude` (Claude Code configuration, which belongs to work). On a new machine,
if you copy your wallpapers to `~/Pictures/Wallpapers` before the first login, the last one used (remembered
in `look.conf`) is picked up; otherwise the default is used.

If you start configuring a new app, add its path to the `MANAGED` array in `install.sh`.

## Testing in a VM

`test/vm.sh` installs everything from scratch in a virtual machine (QEMU/KVM, UEFI, 3D video), without touching
your system. The files live in `~/VMs/hypr-setup-test`; the VM has 4 vCPUs, 6 GB and SSH on `localhost:2222`.

```bash
test/vm.sh deps            # shows the QEMU command with 3D video (run with sudo)
test/vm.sh iso             # downloads the Arch ISO and checks the sha256
test/vm.sh create          # 40 GB disk + UEFI NVRAM
test/vm.sh live            # boots from the ISO; the SSH key goes in on its own (cloud-init)
test/vm.sh install         # Base Arch: GRUB UEFI, ext4, user tester/tester (test/arch-base.sh)
test/vm.sh ssh poweroff && test/vm.sh run    # boots again from the disk
test/vm.sh setup           # copies this repository and runs ./install.sh (log: test/vm.sh ssh tail -f install.log)
test/vm.sh destroy         # deletes the VM (the ISO stays)
```

At the end, log in in the VM window (tester / tester). The VM's sudo doesn't ask for a password and port 22 is
open in the firewall (`/etc/nftables.d/input/ssh.nft`) — only in the test VM.

## Tips and known issues

- **Hyprland config:** since 0.55 it is in **Lua** (`hyprland.lua`), no longer `hyprland.conf`.
  Errors show up on screen and in `hyprctl configerrors`.
- **Bar gone?** Waybar is started by `~/.config/hypr/scripts/bar.sh`, which restarts it by itself if
  it hangs (a notification appears). If you closed it on purpose, open it again with `bar.sh`.
  The music on the bar comes from `scripts/media.sh` (playerctl), not from the `mpris` module, which used to hang the bar.
- **New commands in Waybar:** use `setsid -f <command>` in `on-click`. The session runs attached to
  `tty1`, and without `setsid` programs like Rofi can freeze.
- **Font size on the bar/menus:** don't put `font-size` in `waybar/style.css`, `swaync/style.css`
  or `rofi/theme.rasi`. The sizes come from the files generated by `look.sh`.
- **Closing Rofi from a script:** use `pkill -x rofi`. Without `-x`, it also matches
  `power-profiles-daemon`.
- **NVIDIA:** `nvidia-smi` shows whether the card is in use. It powers off by itself when idle.
- **Neovim:** if something is missing, run `./install.sh nvim` or use `:Lazy`, `:Mason` and `:checkhealth`.
