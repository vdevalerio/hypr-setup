#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │  hypr-setup — Arch Linux + Hyprland, from zero to a full desktop     │
# │  See README.md for details.                                          │
# │                                                                      │
# │  ./install.sh            full install (packages, system, configs,    │
# │                          shell, Neovim)                              │
# │  ./install.sh dotfiles   only copy the configs to home (no sudo)     │
# │  ./install.sh nvim       only set up Neovim (plugins, LSPs)          │
# │  ./install.sh save       copy the CURRENT configs from home to here  │
# │  ./install.sh sddm       (re)install the login screen theme          │
# │  ./install.sh extras     firewall, zram, fallback kernel, battery... │
# │  ./install.sh data       data profile: SQL, DuckDB, Docker...        │
# │  ./install.sh boot       GRUB theme + Plymouth splash for the theme  │
# │  ./install.sh claude     Claude Code: status line + settings merge    │
# │  ./install.sh tts        natural voices (Piper) for Foliate & co.    │
# │  ./install.sh gaming     Steam, GameMode, MangoHud (needs multilib)  │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail

# ── Adjust here ──────────────────────────────────────────────────────────
SYS_LANG="en_US.UTF-8"        # system language
CONSOLE_KEYMAP="br-abnt2"     # console (TTY) keyboard
XKB_LAYOUT="br"               # login screen keyboard (also in hypr/hyprland.lua)
XKB_MODEL="abnt2"

# Personal apps (remove what you don't want). The SUPER+B shortcut opens "brave":
# if you drop brave-bin, change `browser` in dotfiles/.config/hypr/binds.lua.
PERSONAL_PKGS=(keepassxc htop tmux openssh qrencode vim man-db man-pages texinfo bash-completion wget pnpm)
PERSONAL_AUR=(brave-bin claude-desktop)
INSTALL_CLAUDE_CODE=1         # Claude Code (CLI) via the official installer; 0 to skip
# ────────────────────────────────────────────────────────────────────────

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS="$REPO/dotfiles"

# Managed configs (paths relative to home)
MANAGED=(
    .config/hypr
    .config/waybar
    .config/rofi
    .config/swaync
    .config/quickshell
    .config/kitty
    .config/fcitx5
    .config/yazi
    .config/zathura
    .config/lsd
    .config/nvim
    .config/starship.toml
    .config/git/config
    .config/git/ignore
    .config/qt6ct/qt6ct.conf
    .config/atuin/config.toml
    .config/direnv/direnv.toml
    .config/tealdeer/config.toml
    .config/lazygit/config.yml
    .config/btop/btop.conf
    .config/fastfetch/config.jsonc
    .config/gtk-3.0/settings.ini
    .config/gtk-3.0/gtk.css
    .config/gtk-4.0/settings.ini
    .config/gtk-4.0/gtk.css
    .config/user-dirs.dirs
    .config/user-dirs.locale
    .zshrc
    .config/markdownlint
    .icons/default/index.theme
    .local/share/applications/yazi-kitty.desktop
    .local/share/applications/speechify.desktop
    .local/bin/foliate-sentences
    .local/bin/game
    .config/gamemode.ini
    .local/share/piper-speechd
    .local/share/fcitx5/themes/hypr-setup
    .config/systemd/user/backup.service
    .config/systemd/user/backup.timer
    .config/systemd/user/hyprpolkitagent.service.d/igpu.conf
    .config/brave-flags.conf
    .config/claude-desktop-flags.conf
    .config/mimeapps.list
    .claude/statusline.sh
    .claude/hooks/friction-log.mjs
    .claude/skills/forge-skills
    .claude/skills/retro
)
# Default wallpapers: only copied at install time (if missing). Your own wallpapers, profile
# picture and other personal files are not part of the package.
DEFAULT_WALLS=(Pictures/Wallpapers/aurora.mp4 Pictures/Wallpapers/catppuccin-mountains.png)
SAVE_EXCLUDE=(.config/hypr/wallpaper.png .config/hypr/themes/__pycache__ .config/fcitx5/conf/cached_layouts .config/nvim/spell/en.utf-8.add.spl .config/nvim/spell/pt.utf-8.add.spl .config/nvim/spell/tech.utf-8.add.spl)

# ── Packages (official repositories) ─────────────────────────────────────
PKGS_HYPR=(hyprland hyprlock hypridle quickshell qt6-multimedia qt6-multimedia-ffmpeg hyprpolkitagent hyprpicker hyprsunset hyprland-guiutils hyprshutdown
           xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs xdg-utils qt5-wayland qt6-wayland)
PKGS_DESKTOP=(rofi rofi-emoji rofi-calc swaync libnotify awww ffmpeg file)
PKGS_APPS=(kitty yazi poppler resvg 7zip unzip gvfs gvfs-mtp ffmpegthumbnailer file-roller
           firefox mpv imv btop fastfetch libva-utils
           foliate zathura zathura-pdf-mupdf speech-dispatcher espeak-ng)   # document readers (+ TTS for Foliate)
PKGS_AUDIO=(pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol playerctl sof-firmware)
PKGS_SYSTEM=(networkmanager network-manager-applet bluez bluez-utils blueman power-profiles-daemon brightnessctl
             ddcutil    # external monitor brightness (DDC/CI)
             udiskie udisks2 reflector
             nftables zram-generator pacman-contrib fwupd linux-headers dkms)
PKGS_CAPTURE=(grim slurp satty wl-clipboard cliphist jq imagemagick gpu-screen-recorder
              tesseract tesseract-data-eng tesseract-data-por tesseract-data-jpn tesseract-data-rus)
PKGS_BACKUP=(restic rclone)
PKGS_LOOK=(ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji noto-fonts-cjk adwaita-fonts
           papirus-icon-theme adw-gtk-theme nwg-look qt6ct)
PKGS_INPUT=(fcitx5 fcitx5-mozc fcitx5-gtk fcitx5-qt fcitx5-configtool)   # languages: PT, EN, RU, JA
PKGS_LOGIN=(sddm xorg-server xorg-xrandr qt6-multimedia qt6-multimedia-ffmpeg qt6-svg qt6-declarative gnome-keyring)
PKGS_SHELL=(zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search
            starship fzf zoxide lsd eza bat fd ripgrep lazygit git-delta
            atuin direnv mise tealdeer plocate)
PKGS_DEV=(neovim git github-cli base-devel python-pip python-pynvim uv ipython nodejs npm tree-sitter-cli luarocks)
# waybar-git: 0.15.0 sends commands in the old format and Hyprland with a Lua config rejects them
# (clicking a workspace does nothing). Fixed in Waybar's code in 2026-08; go back to the
# "waybar" package (in PKGS_DESKTOP) once 0.16 is out.
# Data profile (./install.sh data — not part of the full install): analysis, SQL, reports
PKGS_DATA=(dbeaver postgresql mariadb-clients pgcli duckdb libreoffice-fresh
           docker docker-compose docker-buildx)
UV_TOOLS_DATA=("harlequin[postgres,mysql]" mycli)   # terminal SQL IDE; MySQL client

AUR_PKGS=(mpvpaper bibata-cursor-theme-bin waybar-git)
# Battery charge limit (Acer laptops only; on others, the install just warns and moves on)
AUR_BATTERY=(acer-wmi-battery-dkms-git)

# Neovim: syntax parsers and language servers (Mason)
TS_PARSERS=(python sql csv markdown markdown_inline toml yaml json rst requirements lua bash regex vim vimdoc
            dockerfile git_config gitcommit diff)
MASON_PKGS=(basedpyright ruff debugpy json-lsp yaml-language-server taplo marksman lua-language-server
            dockerfile-language-server docker-compose-language-service stylua shfmt sqlfluff hadolint
            markdownlint-cli2 markdown-toc prettier)

# ── Utilities ───────────────────────────────────────────────────────────
step() { printf '\n\e[1;35m==>\e[0m \e[1m%s\e[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\e[1;33m  ! %s\e[0m\n' "$*"; }

need_user() {
    if [[ $EUID -eq 0 ]]; then
        echo "Run as a normal user (the script calls sudo when needed)." >&2
        exit 1
    fi
}

sudo_keepalive() {
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
}

# ── Steps ───────────────────────────────────────────────────────────────
setup_pacman() {
    step "pacman: colors and parallel downloads"
    sudo sed -i 's/^#Color/Color/; s/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
    grep -q '^ILoveCandy' /etc/pacman.conf || sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
    sudo pacman -Sy --needed --noconfirm pciutils
}

detect_hardware() {
    step "Detecting hardware"
    CPU_UCODE=()
    case "$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')" in
        AuthenticAMD) CPU_UCODE=(amd-ucode) ;;
        GenuineIntel) CPU_UCODE=(intel-ucode) ;;
    esac
    GPU_LINES=$(lspci -D -d ::03xx)
    NV_ID=$(grep -i 'nvidia' <<<"$GPU_LINES" | head -1 | cut -d' ' -f1 || true)
    IGPU_ID=$(grep -iv 'nvidia' <<<"$GPU_LINES" | grep -E '\b(AMD|ATI)\b|Intel' | head -1 | cut -d' ' -f1 || true)

    GPU_PKGS=(mesa)
    if grep -qE '\b(AMD|ATI)\b' <<<"$GPU_LINES"; then GPU_PKGS+=(vulkan-radeon); fi
    if grep -q 'Intel' <<<"$GPU_LINES"; then GPU_PKGS+=(vulkan-intel intel-media-driver); fi
    if [[ -n $NV_ID ]]; then
        # nvidia-open: Turing cards (GTX 16xx / RTX 20xx) or newer
        local kernels
        kernels=$(pacman -Qq | grep -E '^linux(-lts|-zen|-hardened)?$' || true)
        if [[ $kernels == linux ]]; then
            GPU_PKGS+=(nvidia-open nvidia-utils)
        else
            GPU_PKGS+=(nvidia-open-dkms nvidia-utils)
            for k in $kernels; do GPU_PKGS+=("$k-headers"); done
        fi
        if [[ -n $IGPU_ID ]]; then GPU_PKGS+=(nvidia-prime); fi
    fi
    info "CPU microcode: ${CPU_UCODE[*]:-none}"
    info "GPUs:"; sed 's/^/      /' <<<"$GPU_LINES"
    info "Video packages: ${GPU_PKGS[*]}"
}

install_packages() {
    step "Updating the system and installing packages"
    sudo pacman -Syu --needed --noconfirm \
        "${PKGS_HYPR[@]}" "${PKGS_DESKTOP[@]}" "${PKGS_APPS[@]}" "${PKGS_AUDIO[@]}" "${PKGS_SYSTEM[@]}" \
        "${PKGS_CAPTURE[@]}" "${PKGS_LOOK[@]}" "${PKGS_INPUT[@]}" "${PKGS_LOGIN[@]}" "${PKGS_BACKUP[@]}" "${PKGS_SHELL[@]}" "${PKGS_DEV[@]}" \
        "${GPU_PKGS[@]}" "${CPU_UCODE[@]}" "${PERSONAL_PKGS[@]}"
}

install_aur() {
    step "AUR: yay"
    if ! command -v yay >/dev/null; then
        local tmp; tmp=$(mktemp -d)
        git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
    step "AUR: packages"
    local p
    for p in "${AUR_PKGS[@]}" "${PERSONAL_AUR[@]}"; do
        yay -S --needed --noconfirm "$p" || warn "Failed to install $p (continuing)"
    done
}

setup_system() {
    if [[ -n $IGPU_ID && -n $NV_ID ]]; then
        step "Hybrid GPU: links /dev/dri/igpu e /dev/dri/dgpu"
        printf '%s\n' \
            "KERNEL==\"card*\", KERNELS==\"$IGPU_ID\", SUBSYSTEM==\"drm\", SYMLINK+=\"dri/igpu\"" \
            "KERNEL==\"card*\", KERNELS==\"$NV_ID\", SUBSYSTEM==\"drm\", SYMLINK+=\"dri/dgpu\"" |
            sudo tee /etc/udev/rules.d/90-gpu-symlinks.rules >/dev/null
        sudo udevadm control --reload
        sudo udevadm trigger --subsystem-match=drm || true
    fi
    if [[ -n $NV_ID ]]; then
        step "NVIDIA: suspend and power saving"
        sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
        echo 'options nvidia "NVreg_DynamicPowerManagement=0x02"' | sudo tee /etc/modprobe.d/nvidia-pm.conf >/dev/null
        sudo install -Dm644 "$REPO/system/etc/udev/rules.d/80-nvidia-pm.rules" /etc/udev/rules.d/80-nvidia-pm.rules
        echo auto | sudo tee /sys/bus/pci/devices/$NV_ID/power/control >/dev/null || true
    fi

    step "External monitor brightness (DDC/CI): i2c-dev module"
    echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
    sudo modprobe i2c-dev || true

    step "Language ($SYS_LANG) and keyboard ($CONSOLE_KEYMAP / $XKB_LAYOUT $XKB_MODEL)"
    sudo sed -i "s/^#\s*${SYS_LANG} UTF-8/${SYS_LANG} UTF-8/" /etc/locale.gen
    sudo locale-gen
    sudo localectl set-locale "LANG=$SYS_LANG"
    sudo localectl set-keymap "$CONSOLE_KEYMAP" || true
    sudo localectl set-x11-keymap "$XKB_LAYOUT" "$XKB_MODEL" || true

    setup_sddm

    step "Services"
    sudo systemctl enable NetworkManager bluetooth power-profiles-daemon sddm
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

    if command -v grub-mkconfig >/dev/null && [[ -f /boot/grub/grub.cfg ]]; then
        step "GRUB (microcode)"
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

# Login screen styled like the lock screen (theme in system/sddm/hypr-setup).
# The dynamic/ folder belongs to the user: ~/.config/hypr/scripts/sddm-sync.sh copies the
# background, colors and photo there, because SDDM can't read the home directory.
setup_sddm() {
    step "Login screen (SDDM): hypr-setup theme"
    # xrandr: Xsetup (mirrored monitors) · qt6-multimedia: animated background. Before copying the theme:
    # without Qt Multimedia the theme doesn't load.
    sudo pacman -S --needed --noconfirm xorg-xrandr qt6-multimedia qt6-multimedia-ffmpeg
    local dst=/usr/share/sddm/themes/hypr-setup
    sudo mkdir -p "$dst/dynamic"
    sudo cp -r "$REPO/system/sddm/hypr-setup/." "$dst/"
    sudo chown "$USER:$USER" "$dst/dynamic"
    sudo chmod 755 "$dst/dynamic"
    sudo ln -sfn dynamic/theme.conf.user "$dst/theme.conf.user"
    # Login mirrored on all monitors (including those wired to the NVIDIA GPU, on hybrid laptops)
    sudo install -m 755 "$REPO/system/sddm/Xsetup" /usr/share/sddm/scripts/hypr-setup-Xsetup
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=hypr-setup\nCursorTheme=Bibata-Modern-Classic\nCursorSize=24\n\n[General]\nNumlock=on\n\n[X11]\nDisplayCommand=/usr/share/sddm/scripts/hypr-setup-Xsetup\n' |
        sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null
    [[ -x $HOME/.config/hypr/scripts/sddm-sync.sh ]] && "$HOME/.config/hypr/scripts/sddm-sync.sh" --force || true
}

# Protection and maintenance (files in system/etc/, mirroring /etc):
# firewall, SSD TRIM, pacman cache cleanup, firmware, zram, lid and battery limit.
setup_extras() {
    step "Packages: firewall, zram, maintenance, screen recording, OCR, backup, GitHub"
    sudo pacman -S --needed --noconfirm nftables zram-generator pacman-contrib fwupd linux-headers dkms \
        gpu-screen-recorder tesseract tesseract-data-{eng,por,jpn,rus} restic rclone github-cli \
        timeshift rsync smartmontools jq wireguard-tools tailscale

    step "Firewall (blocks inbound, allows outbound)"
    sudo install -Dm644 "$REPO/system/etc/nftables.conf" /etc/nftables.conf
    sudo install -d /etc/nftables.d/input   # extra per-machine rules (see nftables.conf)
    sudo systemctl enable --now nftables.service
    sudo systemctl restart nftables.service   # applies the new rules (there is no "reload")

    step "Automatic maintenance: SSD TRIM, pacman cache, firmware"
    sudo systemctl enable --now fstrim.timer paccache.timer fwupd-refresh.timer

    step "Safety net: package + /etc snapshot before every update"
    sudo install -Dm755 "$REPO/system/usr/local/bin/hypr-setup-snapshot" /usr/local/bin/hypr-setup-snapshot
    sudo install -Dm644 "$REPO/system/etc/pacman.d/hooks/00-hypr-setup-snapshot.hook" /etc/pacman.d/hooks/00-hypr-setup-snapshot.hook

    step "Rollback points: Timeshift (rsync) snapshot of / before every update (update.sh)"
    sudo install -Dm755 "$REPO/system/usr/local/bin/hypr-setup-rollback" /usr/local/bin/hypr-setup-rollback
    sudo install -d /etc/timeshift
    sed "s/@ROOT_UUID@/$(findmnt -no UUID /)/" "$REPO/system/etc/timeshift/timeshift.json" | sudo tee /etc/timeshift/timeshift.json >/dev/null
    info "Snapshots live in /timeshift on the root partition (/home is not included: backup.sh covers it)."
    info "Create one now: sudo hypr-setup-rollback create · restore: sudo hypr-setup-rollback restore"

    step "Disk health: SMART summary every 6 h (warnings come from health-watch.sh)"
    sudo install -Dm755 "$REPO/system/usr/local/bin/hypr-setup-smart" /usr/local/bin/hypr-setup-smart
    sudo install -Dm644 "$REPO/system/etc/systemd/system/hypr-setup-smart.service" /etc/systemd/system/hypr-setup-smart.service
    sudo install -Dm644 "$REPO/system/etc/systemd/system/hypr-setup-smart.timer" /etc/systemd/system/hypr-setup-smart.timer
    sudo systemctl daemon-reload
    sudo systemctl enable --now hypr-setup-smart.timer

    step "VPN: WireGuard (through NetworkManager) and Tailscale"
    sudo systemctl enable tailscaled.service
    sudo systemctl restart tailscaled.service   # nftables.conf flushed the ruleset: tailscaled rebuilds its rules
    sleep 2
    sudo tailscale set --operator "$USER" || warn "tailscale: run 'sudo tailscale set --operator \$USER' later"
    info "Add a WireGuard tunnel: control center → Tools → VPN → Import. Tailscale: same menu (signs in once)."

    step "Fallback kernel (linux-lts): if an update breaks boot, pick it in GRUB (Advanced options)"
    sudo pacman -S --needed --noconfirm linux-lts linux-lts-headers linux-headers
    if pacman -Qq nvidia-open &>/dev/null; then
        info "NVIDIA: nvidia-open → nvidia-open-dkms (module built for both kernels)"
        sudo pacman -S --needed --noconfirm --ask=4 nvidia-open-dkms   # --ask=4: accepts removing the conflicting package
    fi
    if command -v grub-mkconfig >/dev/null && [[ -f /boot/grub/grub.cfg ]]; then
        # GRUB sorts kernels by name and would make linux-lts the main entry
        if grep -q '^#\?GRUB_TOP_LEVEL=' /etc/default/grub; then
            sudo sed -i 's|^#\?GRUB_TOP_LEVEL=.*|GRUB_TOP_LEVEL="/boot/vmlinuz-linux"|' /etc/default/grub
        else
            echo 'GRUB_TOP_LEVEL="/boot/vmlinuz-linux"' | sudo tee -a /etc/default/grub >/dev/null
        fi
        # Hidden menu: boot doesn't wait 5 s; hold Esc or Shift to see the menu (and linux-lts)
        sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/; s/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    step "pacman mirrors: the fastest ones (Brazil + US), refreshed weekly"
    sudo pacman -S --needed --noconfirm reflector plocate
    sudo install -Dm644 "$REPO/system/etc/xdg/reflector/reflector.conf" /etc/xdg/reflector/reflector.conf
    sudo systemctl enable reflector.timer plocate-updatedb.timer
    sudo systemctl start plocate-updatedb.service || true

    step "zram (compressed swap in memory)"
    sudo install -Dm644 "$REPO/system/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
    sudo install -Dm644 "$REPO/system/etc/sysctl.d/99-zram.conf" /etc/sysctl.d/99-zram.conf
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service || warn "zram: activates on next boot"
    sudo sysctl -q --system

    step "Laptop lid (doesn't suspend with an external monitor; takes effect after reboot)"
    sudo install -Dm644 "$REPO/system/etc/systemd/logind.conf.d/10-lid.conf" /etc/systemd/logind.conf.d/10-lid.conf

    if grep -qi acer /sys/class/dmi/id/sys_vendor 2>/dev/null && [[ -d /sys/class/power_supply/BAT0 || -d /sys/class/power_supply/BAT1 ]]; then
        step "Battery charge limit at 80% (acer-wmi-battery)"
        sudo install -Dm644 "$REPO/system/etc/modprobe.d/acer-wmi-battery.conf" /etc/modprobe.d/acer-wmi-battery.conf
        if yay -S --needed --noconfirm "${AUR_BATTERY[@]}" && sudo modprobe acer-wmi-battery enable_health_mode=1; then
            info "health_mode = $(cat /sys/bus/wmi/drivers/acer-wmi-battery/health_mode 2>/dev/null || echo '?') (1 = 80% limit active)"
        else
            warn "Battery limit not available on this model/kernel (the rest carries on as normal)"
        fi
    fi
}

# Data profile: SQL clients, DuckDB, LibreOffice (to open third-party .xlsx) and Docker for
# local test databases. The PostgreSQL server ships with the package but stays off (psql only).
setup_data() {
    step "Data profile: packages"
    sudo pacman -S --needed --noconfirm "${PKGS_DATA[@]}"

    step "Docker (starts on demand, via the socket)"
    sudo systemctl enable --now docker.socket
    # docker group = root power via Docker; it's the norm on development machines
    if ! id -nG "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER"
        info "You were added to the docker group: takes effect on next login"
    fi

    step "Terminal tools (uv tool)"
    local t
    for t in "${UV_TOOLS_DATA[@]}"; do
        uv tool install --quiet "$t" 2>/dev/null || uv tool upgrade --quiet "${t%%[*}" || warn "$t failed"
    done
}

# Boot that matches the desktop: GRUB theme and Plymouth splash with the colors and background
# of the current theme (system/boot/make-themes.sh). Run again after switching themes to update.
set_grub() { # set_grub <VAR> <value>: replaces or appends the line in /etc/default/grub
    if grep -q "^#\?$1=" /etc/default/grub; then
        sudo sed -i "s|^#\?$1=.*|$1=$2|" /etc/default/grub
    else
        echo "$1=$2" | sudo tee -a /etc/default/grub >/dev/null
    fi
}

setup_boot() {
    step "Boot: Plymouth (splash) and themes"
    sudo pacman -S --needed --noconfirm plymouth imagemagick
    local tmp; tmp=$(mktemp -d)
    "$REPO/system/boot/make-themes.sh" "$tmp"
    sudo rm -rf /boot/grub/themes/hypr-setup /usr/share/plymouth/themes/hypr-setup
    sudo install -d /boot/grub/themes
    sudo cp -r "$tmp/grub" /boot/grub/themes/hypr-setup
    sudo cp -r "$tmp/plymouth" /usr/share/plymouth/themes/hypr-setup
    rm -rf "$tmp"
    sudo plymouth-set-default-theme hypr-setup

    step "Boot: splash in the initramfs (plymouth hook) and on the kernel command line"
    if ! grep -q '^HOOKS=.*plymouth' /etc/mkinitcpio.conf; then
        sudo sed -i -E '/^HOOKS=/ s/\b(systemd|udev)\b/\1 plymouth/' /etc/mkinitcpio.conf
    fi
    local cmdline; cmdline=$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/\1/p' /etc/default/grub)
    [[ " $cmdline " == *" splash "* ]] || set_grub GRUB_CMDLINE_LINUX_DEFAULT "\"$cmdline splash\""
    set_grub GRUB_THEME '"/boot/grub/themes/hypr-setup/theme.txt"'
    set_grub GRUB_TIMEOUT_STYLE hidden   # Esc/Shift at power-on shows the menu
    set_grub GRUB_TIMEOUT 1
    set_grub GRUB_DISABLE_BOOTNEXT true  # no "EFI BootNext" entries (PXE, shell...) from GRUB 2.16
    sudo mkinitcpio -P
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    info "Done: the splash shows on the next boot (hold Esc to see the GRUB menu)"
}

# Claude Code: status line script + settings fragment (claude/settings.json) merged into
# ~/.claude/settings.json. Merged, not copied: other tools (e.g. the company's Growth Opera
# installer) keep their own hooks there. Objects are merged deeply; permissions.allow is a union.
setup_claude() {
    step "Claude Code: status line, settings, forge skills"
    command -v jq >/dev/null || sudo pacman -S --needed --noconfirm jq
    install -Dm755 "$DOTS/.claude/statusline.sh" "$HOME/.claude/statusline.sh"
    install -Dm755 "$DOTS/.claude/hooks/friction-log.mjs" "$HOME/.claude/hooks/friction-log.mjs"
    mkdir -p "$HOME/.claude/skills" && cp -r "$DOTS/.claude/skills/." "$HOME/.claude/skills/"
    local cur="$HOME/.claude/settings.json" tmp
    [[ -s $cur ]] || echo '{}' > "$cur"
    cp "$cur" "$cur.bak.hypr-setup"
    tmp=$(mktemp)
    jq -s '.[0] as $cur | .[1] as $new
        | ($cur * ($new | del(.permissions, .hooks)))
        | .hooks = (reduce (($new.hooks // {}) | to_entries[]) as $e ($cur.hooks // {};
            .[$e.key] = ((.[$e.key] // []) + $e.value | unique)))
        | .permissions.allow = ((($cur.permissions.allow // []) + ($new.permissions.allow // [])) | unique)' \
        "$cur" "$REPO/claude/settings.json" > "$tmp" && mv "$tmp" "$cur"
    info "Merged into $cur (backup: settings.json.bak.hypr-setup). Restart Claude Code to apply."
}

deploy_dotfiles() {
    step "Copying configs to home"
    [[ -d $DOTS ]] || { echo "Folder $DOTS not found." >&2; exit 1; }
    local backup="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)" rel src dst moved=0
    for rel in "${MANAGED[@]}"; do
        src="$DOTS/$rel"; dst="$HOME/$rel"
        [[ -e $src ]] || { warn "missing from the package: $rel"; continue; }
        if [[ -e $dst ]] && ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
            mkdir -p "$backup/$(dirname "$rel")"
            mv "$dst" "$backup/$rel"
            moved=1
        fi
        mkdir -p "$(dirname "$dst")"
        if [[ -d $src ]]; then
            mkdir -p "$dst"
            cp -a "$src/." "$dst/"
        else
            cp -a "$src" "$dst"
        fi
    done
    if (( moved )); then info "Old configs that differed were moved to $backup"; fi

    for rel in "${DEFAULT_WALLS[@]}"; do
        mkdir -p "$HOME/$(dirname "$rel")"
        [[ -e $HOME/$rel ]] || cp -a "$DOTS/$rel" "$HOME/$rel"
    done

    # Personal folders in English (Desktop, Documents, Projects, ...)
    local d
    for d in Desktop Documents Downloads Music Pictures Projects Public Templates Videos; do mkdir -p "$HOME/$d"; done
    mkdir -p "$HOME/Pictures/Screenshots"

    # Git: commit signing with the SSH key (if present) and the gnome-keyring SSH agent
    if [[ -f $HOME/.ssh/id_ed25519.pub ]]; then
        printf '%s %s\n' "$(git config --get user.email)" "$(cut -d' ' -f1,2 "$HOME/.ssh/id_ed25519.pub")" \
            > "$HOME/.config/git/allowed_signers"
    else
        warn "No ~/.ssh/id_ed25519: commits won't be signed. Create one with: ssh-keygen -t ed25519 (see README)"
        git config --file "$HOME/.config/git/local" commit.gpgsign false
        git config --file "$HOME/.config/git/local" tag.gpgsign false
    fi
    systemctl --user enable gcr-ssh-agent.socket 2>/dev/null || true

    # Foliate launcher override: sentence-level read-aloud highlighting (absolute path: launchers lack ~/.local/bin in PATH)
    if [[ -f /usr/share/applications/com.github.johnfactotum.Foliate.desktop ]]; then
        sed "s|^Exec=foliate|Exec=$HOME/.local/bin/foliate-sentences|" /usr/share/applications/com.github.johnfactotum.Foliate.desktop \
            > "$HOME/.local/share/applications/com.github.johnfactotum.Foliate.desktop"
    fi

    # Yazi opens folders
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    if command -v xdg-mime >/dev/null; then
        xdg-mime default yazi-kitty.desktop inode/directory
        # Document readers: PDF in Zathura, e-books in Foliate (only when their desktop files exist)
        local apps=/usr/share/applications
        [[ -f $apps/org.pwmt.zathura-pdf-mupdf.desktop ]] && xdg-mime default org.pwmt.zathura-pdf-mupdf.desktop application/pdf
        [[ -f $apps/com.github.johnfactotum.Foliate.desktop ]] &&
            xdg-mime default com.github.johnfactotum.Foliate.desktop application/epub+zip application/x-mobipocket-ebook
    fi
}

# Gaming (not part of the full install: Steam brings a lot of 32-bit libraries). Needs the multilib
# repository. Steam itself runs on the integrated GPU (igpu.sh) so the desktop keeps the NVIDIA GPU asleep;
# each game opts in with the Steam launch option `game %command%` (dGPU + GameMode + MangoHud).
setup_gaming() {
    step "Gaming: multilib repository"
    if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
        sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
        sudo pacman -Sy
    fi
    step "Gaming: Steam, GameMode, MangoHud"
    sudo pacman -S --needed --noconfirm steam gamemode lib32-gamemode mangohud lib32-mangohud \
        lib32-nvidia-utils lib32-vulkan-radeon lib32-mesa
    # Steam launcher override: the Steam window itself must not wake the NVIDIA GPU
    mkdir -p "$HOME/.local/share/applications"
    if [[ -f /usr/share/applications/steam.desktop ]]; then
        sed "s|^Exec=\(/usr/bin/\)\?steam|Exec=$HOME/.config/hypr/scripts/igpu.sh /usr/bin/steam|" /usr/share/applications/steam.desktop \
            > "$HOME/.local/share/applications/steam.desktop"
    fi
    info "In Steam: game → Properties → Launch options →  game %command%"
}

# Natural text-to-speech: Piper plus our own speech-dispatcher module. The stock sd_generic module
# strips SSML, so clients (Foliate) never get index marks and cannot highlight the word being read;
# .local/share/piper-speechd/sd_piper emits them. Voice per language: SUPER + SHIFT + V (voice.sh).
setup_tts() {
    step "Text-to-speech: Piper + voices"
    if ! command -v piper-tts >/dev/null; then
        # The AUR package ships a stale checksum for its 3-line wrapper script; retry without checks
        yay -S --needed --noconfirm piper-tts-bin ||
            yay -S --needed --noconfirm --mflags --skipchecksums piper-tts-bin ||
            { warn "piper-tts-bin failed (retry: ./install.sh tts)"; return 0; }
    fi
    local dir=$HOME/.local/share/piper base=https://huggingface.co/rhasspy/piper-voices/resolve/main v
    mkdir -p "$dir"
    for v in pt/pt_BR/faber/medium/pt_BR-faber-medium en/en_US/ryan/high/en_US-ryan-high; do
        [[ -f $dir/${v##*/}.onnx ]] ||
            curl -fL --output-dir "$dir" -O "$base/$v.onnx" -O "$base/$v.onnx.json" || warn "Voice ${v##*/} failed"
    done
    # speechd config: the system one with our module as default (the path must be absolute)
    local cfg=$HOME/.config/speech-dispatcher
    mkdir -p "$cfg/modules"
    : > "$cfg/modules/piper.conf"
    sed 's/^DefaultModule .*/DefaultModule piper/' /etc/speech-dispatcher/speechd.conf > "$cfg/speechd.conf"
    printf '\nAddModule "piper" "%s/.local/share/piper-speechd/sd_piper" "piper.conf"\n' "$HOME" >> "$cfg/speechd.conf"
    pkill -x speech-dispatch || true   # restarts with the new config on the next use
}

setup_shell() {
    step "Default shell: zsh"
    [[ "$(getent passwd "$USER" | cut -d: -f7)" == /usr/bin/zsh ]] || sudo chsh -s /usr/bin/zsh "$USER"
    if (( INSTALL_CLAUDE_CODE )) && ! command -v claude >/dev/null && [[ ! -x $HOME/.local/bin/claude ]]; then
        step "Claude Code (CLI)"
        curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code failed (install later: https://claude.ai/install.sh)"
    fi
    step "jupytext (.ipynb notebooks in Neovim)"
    uv tool install --quiet jupytext 2>/dev/null || uv tool upgrade --quiet jupytext || warn "jupytext failed"
}

setup_nvim() {
    step "Neovim: plugins (versions pinned in lazy-lock.json)"
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true

    step "Neovim: Portuguese spell dictionary"
    # The runtime ships only en; nvim would ask to download pt on first use
    local spell="$HOME/.local/share/nvim/site/spell"
    [[ -s $spell/pt.utf-8.spl ]] || curl -fsSL --create-dirs -o "$spell/pt.utf-8.spl" \
        https://ftp.nluug.nl/pub/vim/runtime/spell/pt.utf-8.spl || warn "pt spell dictionary download failed"

    step "Neovim: syntax parsers"
    # grep -o: nvim-treesitter's progress output has no line breaks, so the result comes glued to the end
    local ts_list mason_list
    ts_list=$(printf '"%s",' "${TS_PARSERS[@]}")
    nvim --headless -c "lua vim.defer_fn(function()
        local ts = require('nvim-treesitter')
        ts.install({${ts_list}}):wait(600000)
        print('parsers: ' .. #ts.get_installed())
        vim.cmd('qa!') end, 1000)" 2>&1 | grep -oE 'parsers: [0-9]+' || warn "parsers: check with :checkhealth"

    step "Neovim: language servers and tools (Mason)"
    mason_list=$(printf '"%s",' "${MASON_PKGS[@]}")
    nvim --headless -c 'Lazy load mason.nvim' -c "lua
        local reg = require('mason-registry')
        local names, deadline = {${mason_list}}, vim.uv.now() + 900000
        reg.refresh(function()
          -- LazyVim already installs part of the list on its own (ensure_installed) when Mason loads:
          -- a package being installed doesn't accept another install (assert), so just wait for it
          for _, name in ipairs(names) do
            local ok, p = pcall(reg.get_package, name)
            if ok and not p:is_installed() and not p:is_installing() then
              pcall(p.install, p)
            end
          end
          local function wait()
            local busy = vim.tbl_filter(function(n)
              local ok, p = pcall(reg.get_package, n); return ok and p:is_installing() end, names)
            if #busy == 0 or vim.uv.now() > deadline then
              local missing = vim.tbl_filter(function(n)
                local ok, p = pcall(reg.get_package, n); return not (ok and p:is_installed()) end, names)
              print('mason: ' .. #reg.get_installed_package_names() .. ' installed'
                .. (#missing > 0 and (' | missing: ' .. table.concat(missing, ' ')) or ''))
              vim.cmd('qa!')
            else vim.defer_fn(wait, 1000) end
          end
          vim.defer_fn(wait, 1000)
        end)" 2>&1 | grep -oE 'mason: .*' || warn "mason: check with :Mason"
}

save_dotfiles() {
    step "Saving current configs from home to $DOTS"
    local rel src dst ex
    for rel in "${MANAGED[@]}"; do
        src="$HOME/$rel"; dst="$DOTS/$rel"
        [[ -e $src ]] || { warn "not in home: $rel"; continue; }
        rm -rf "$dst"
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
    done
    for ex in "${SAVE_EXCLUDE[@]}"; do rm -rf "${DOTS:?}/$ex"; done

    info "Done. Size: $(du -sh "$DOTS" | cut -f1)"
}

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; }

# ── Main ───────────────────────────────────────────────────────────────
case "${1:-all}" in
    all)
        need_user
        step "Asking for the sudo password (just once)"
        sudo_keepalive
        setup_pacman
        detect_hardware
        install_packages
        install_aur
        setup_system
        setup_extras
        deploy_dotfiles
        setup_tts
        setup_shell
        setup_nvim
        setup_claude
        printf '\n\e[1;32mDone!\e[0m Reboot (sudo reboot) and log into the "Hyprland" session.\n'
        printf 'On first login the animated wallpaper is applied and the colors are generated. SUPER + F1 shows the shortcuts.\n'
        ;;
    dotfiles) need_user; deploy_dotfiles ;;
    nvim)     need_user; setup_nvim ;;
    save)     need_user; save_dotfiles ;;
    sddm)     need_user; setup_sddm ;;
    extras)   need_user; sudo_keepalive; setup_extras ;;
    data)     need_user; sudo_keepalive; setup_data ;;
    boot)     need_user; sudo_keepalive; setup_boot ;;
    claude)   need_user; setup_claude ;;
    tts)      need_user; setup_tts ;;
    gaming)   need_user; sudo_keepalive; setup_gaming ;;
    -h|--help|help) usage ;;
    *) usage; exit 1 ;;
esac
