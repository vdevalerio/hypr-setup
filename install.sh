#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │  hypr-setup — Arch Linux + Hyprland, do zero ao desktop completo     │
# │  Veja README.md para detalhes.                                       │
# │                                                                      │
# │  ./install.sh            instalação completa (pacotes, sistema,      │
# │                          configs, shell, Neovim)                     │
# │  ./install.sh dotfiles   só copia as configs para a home (sem sudo)  │
# │  ./install.sh nvim       só prepara o Neovim (plugins, LSPs)         │
# │  ./install.sh save       copia as configs ATUAIS da home para cá     │
# │  ./install.sh sddm       (re)instala o tema da tela de login         │
# │  ./install.sh extras     firewall, zram, kernel reserva, bateria...  │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail

# ── Ajuste aqui ─────────────────────────────────────────────────────────
SYS_LANG="en_US.UTF-8"        # idioma do sistema
CONSOLE_KEYMAP="br-abnt2"     # teclado no console (TTY)
XKB_LAYOUT="br"               # teclado na tela de login (também em hypr/hyprland.lua)
XKB_MODEL="abnt2"

# Apps pessoais (remova o que não quiser). O atalho SUPER+B abre o "brave":
# se tirar o brave-bin, troque `browser` em dotfiles/.config/hypr/binds.lua.
PERSONAL_PKGS=(keepassxc htop tmux openssh qrencode vim man-db man-pages texinfo bash-completion wget pnpm)
PERSONAL_AUR=(brave-bin claude-desktop)
INSTALL_CLAUDE_CODE=1         # Claude Code (CLI) pelo instalador oficial; 0 para pular
# ────────────────────────────────────────────────────────────────────────

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS="$REPO/dotfiles"

# Configs gerenciadas (caminhos relativos à home)
MANAGED=(
    .config/hypr
    .config/waybar
    .config/rofi
    .config/swaync
    .config/kitty
    .config/fcitx5
    .config/yazi
    .config/lsd
    .config/nvim
    .config/starship.toml
    .config/git/config
    .config/git/ignore
    .config/qt6ct/qt6ct.conf
    .config/atuin/config.toml
    .config/direnv/direnv.toml
    .config/tealdeer/config.toml
    .config/gtk-3.0/settings.ini
    .config/gtk-3.0/gtk.css
    .config/gtk-4.0/settings.ini
    .config/gtk-4.0/gtk.css
    .config/user-dirs.dirs
    .config/user-dirs.locale
    .zshrc
    .icons/default/index.theme
    .local/share/applications/yazi-kitty.desktop
    .local/share/fcitx5/themes/hypr-setup
    .config/systemd/user/backup.service
    .config/systemd/user/backup.timer
    .config/brave-flags.conf
    .config/claude-desktop-flags.conf
    .config/mimeapps.list
)
# Wallpapers padrão: só copiados na instalação (se faltarem). Os seus wallpapers, a foto de
# perfil e outros arquivos pessoais não entram no pacote.
DEFAULT_WALLS=(Pictures/Wallpapers/aurora.mp4 Pictures/Wallpapers/catppuccin-mountains.png)
SAVE_EXCLUDE=(.config/hypr/wallpaper.png .config/hypr/themes/__pycache__ .config/fcitx5/conf/cached_layouts)

# ── Pacotes (repositórios oficiais) ─────────────────────────────────────
PKGS_HYPR=(hyprland hyprlock hypridle hyprpolkitagent hyprpicker hyprsunset hyprland-guiutils hyprshutdown
           xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs xdg-utils qt5-wayland qt6-wayland)
PKGS_DESKTOP=(waybar rofi rofi-emoji rofi-calc swaync libnotify awww ffmpeg file)
PKGS_APPS=(kitty yazi poppler resvg 7zip unzip gvfs gvfs-mtp ffmpegthumbnailer file-roller
           firefox mpv imv btop fastfetch)
PKGS_AUDIO=(pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol playerctl sof-firmware)
PKGS_SYSTEM=(networkmanager network-manager-applet bluez bluez-utils blueman power-profiles-daemon brightnessctl
             ddcutil    # brilho de monitores externos (DDC/CI)
             udiskie udisks2 reflector
             nftables zram-generator pacman-contrib fwupd linux-headers dkms)
PKGS_CAPTURE=(grim slurp satty wl-clipboard cliphist jq imagemagick gpu-screen-recorder
              tesseract tesseract-data-eng tesseract-data-por tesseract-data-jpn tesseract-data-rus)
PKGS_BACKUP=(restic rclone)
PKGS_LOOK=(ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji noto-fonts-cjk adwaita-fonts
           papirus-icon-theme adw-gtk-theme nwg-look qt6ct)
PKGS_INPUT=(fcitx5 fcitx5-mozc fcitx5-gtk fcitx5-qt fcitx5-configtool)   # idiomas: PT, EN, RU, JA
PKGS_LOGIN=(sddm xorg-server xorg-xrandr qt6-multimedia qt6-multimedia-ffmpeg qt6-svg qt6-declarative gnome-keyring)
PKGS_SHELL=(zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search
            starship fzf zoxide lsd eza bat fd ripgrep lazygit git-delta
            atuin direnv mise tealdeer plocate)
PKGS_DEV=(neovim git github-cli base-devel python-pip python-pynvim uv ipython nodejs npm tree-sitter-cli luarocks)
AUR_PKGS=(mpvpaper bibata-cursor-theme-bin)
# Limite de carga da bateria (só notebooks Acer; em outros, a instalação só avisa e segue)
AUR_BATTERY=(acer-wmi-battery-dkms-git)

# Neovim: parsers de sintaxe e servidores de linguagem (Mason)
TS_PARSERS=(python sql csv markdown markdown_inline toml yaml json rst requirements lua bash regex vim vimdoc
            dockerfile git_config gitcommit diff)
MASON_PKGS=(basedpyright ruff debugpy json-lsp yaml-language-server taplo marksman lua-language-server
            dockerfile-language-server docker-compose-language-service stylua shfmt sqlfluff hadolint
            markdownlint-cli2 markdown-toc)

# ── Utilidades ──────────────────────────────────────────────────────────
step() { printf '\n\e[1;35m==>\e[0m \e[1m%s\e[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\e[1;33m  ! %s\e[0m\n' "$*"; }

need_user() {
    if [[ $EUID -eq 0 ]]; then
        echo "Rode como usuário normal (o script chama sudo quando precisa)." >&2
        exit 1
    fi
}

sudo_keepalive() {
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
}

# ── Etapas ──────────────────────────────────────────────────────────────
setup_pacman() {
    step "pacman: cores e downloads paralelos"
    sudo sed -i 's/^#Color/Color/; s/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
    grep -q '^ILoveCandy' /etc/pacman.conf || sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
    sudo pacman -Sy --needed --noconfirm pciutils
}

detect_hardware() {
    step "Detectando hardware"
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
        # nvidia-open: placas Turing (GTX 16xx / RTX 20xx) ou mais novas
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
    info "CPU microcode: ${CPU_UCODE[*]:-nenhum}"
    info "GPUs:"; sed 's/^/      /' <<<"$GPU_LINES"
    info "Pacotes de vídeo: ${GPU_PKGS[*]}"
}

install_packages() {
    step "Atualizando o sistema e instalando pacotes"
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
    step "AUR: pacotes"
    local p
    for p in "${AUR_PKGS[@]}" "${PERSONAL_AUR[@]}"; do
        yay -S --needed --noconfirm "$p" || warn "Falhou instalar $p (continuando)"
    done
}

setup_system() {
    if [[ -n $IGPU_ID && -n $NV_ID ]]; then
        step "GPU híbrida: links /dev/dri/igpu e /dev/dri/dgpu"
        printf '%s\n' \
            "KERNEL==\"card*\", KERNELS==\"$IGPU_ID\", SUBSYSTEM==\"drm\", SYMLINK+=\"dri/igpu\"" \
            "KERNEL==\"card*\", KERNELS==\"$NV_ID\", SUBSYSTEM==\"drm\", SYMLINK+=\"dri/dgpu\"" |
            sudo tee /etc/udev/rules.d/90-gpu-symlinks.rules >/dev/null
        sudo udevadm control --reload
        sudo udevadm trigger --subsystem-match=drm || true
    fi
    if [[ -n $NV_ID ]]; then
        step "NVIDIA: suspensão e economia de energia"
        sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
        echo 'options nvidia "NVreg_DynamicPowerManagement=0x02"' | sudo tee /etc/modprobe.d/nvidia-pm.conf >/dev/null
        sudo install -Dm644 "$REPO/system/etc/udev/rules.d/80-nvidia-pm.rules" /etc/udev/rules.d/80-nvidia-pm.rules
        echo auto | sudo tee /sys/bus/pci/devices/$NV_ID/power/control >/dev/null || true
    fi

    step "Brilho de monitores externos (DDC/CI): módulo i2c-dev"
    echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
    sudo modprobe i2c-dev || true

    step "Idioma ($SYS_LANG) e teclado ($CONSOLE_KEYMAP / $XKB_LAYOUT $XKB_MODEL)"
    sudo sed -i "s/^#\s*${SYS_LANG} UTF-8/${SYS_LANG} UTF-8/" /etc/locale.gen
    sudo locale-gen
    sudo localectl set-locale "LANG=$SYS_LANG"
    sudo localectl set-keymap "$CONSOLE_KEYMAP" || true
    sudo localectl set-x11-keymap "$XKB_LAYOUT" "$XKB_MODEL" || true

    setup_sddm

    step "Serviços"
    sudo systemctl enable NetworkManager bluetooth power-profiles-daemon sddm
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

    if command -v grub-mkconfig >/dev/null && [[ -f /boot/grub/grub.cfg ]]; then
        step "GRUB (microcode)"
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

# Tela de login com o visual da tela de bloqueio (tema em system/sddm/hypr-setup).
# A pasta dynamic/ pertence ao usuário: ~/.config/hypr/scripts/sddm-sync.sh copia para lá o fundo,
# as cores e a foto, porque o SDDM não consegue ler a home.
setup_sddm() {
    step "Tela de login (SDDM): tema hypr-setup"
    # xrandr: Xsetup (monitores espelhados) · qt6-multimedia: fundo animado. Antes de copiar o tema:
    # sem o Qt Multimedia o tema não carrega.
    sudo pacman -S --needed --noconfirm xorg-xrandr qt6-multimedia qt6-multimedia-ffmpeg
    local dst=/usr/share/sddm/themes/hypr-setup
    sudo mkdir -p "$dst/dynamic"
    sudo cp -r "$REPO/system/sddm/hypr-setup/." "$dst/"
    sudo chown "$USER:$USER" "$dst/dynamic"
    sudo chmod 755 "$dst/dynamic"
    sudo ln -sfn dynamic/theme.conf.user "$dst/theme.conf.user"
    # Login espelhado em todos os monitores (inclusive os ligados na NVIDIA, em notebooks híbridos)
    sudo install -m 755 "$REPO/system/sddm/Xsetup" /usr/share/sddm/scripts/hypr-setup-Xsetup
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=hypr-setup\nCursorTheme=Bibata-Modern-Classic\nCursorSize=24\n\n[General]\nNumlock=on\n\n[X11]\nDisplayCommand=/usr/share/sddm/scripts/hypr-setup-Xsetup\n' |
        sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null
    [[ -x $HOME/.config/hypr/scripts/sddm-sync.sh ]] && "$HOME/.config/hypr/scripts/sddm-sync.sh" --force || true
}

# Proteção e manutenção (arquivos em system/etc/, espelho do /etc):
# firewall, TRIM do SSD, limpeza do cache do pacman, firmware, zram, tampa e limite de bateria.
setup_extras() {
    step "Pacotes: firewall, zram, manutenção, gravação de tela, OCR, backup, GitHub"
    sudo pacman -S --needed --noconfirm nftables zram-generator pacman-contrib fwupd linux-headers dkms \
        gpu-screen-recorder tesseract tesseract-data-{eng,por,jpn,rus} restic rclone github-cli

    step "Firewall (bloqueia o que entra, libera o que sai)"
    sudo install -Dm644 "$REPO/system/etc/nftables.conf" /etc/nftables.conf
    sudo systemctl enable --now nftables.service
    sudo systemctl restart nftables.service   # aplica as regras novas (não tem "reload")

    step "Manutenção automática: TRIM do SSD, cache do pacman, firmware"
    sudo systemctl enable --now fstrim.timer paccache.timer fwupd-refresh.timer

    step "Rede de segurança: snapshot de pacotes + /etc antes de cada atualização"
    sudo install -Dm755 "$REPO/system/usr/local/bin/hypr-setup-snapshot" /usr/local/bin/hypr-setup-snapshot
    sudo install -Dm644 "$REPO/system/etc/pacman.d/hooks/00-hypr-setup-snapshot.hook" /etc/pacman.d/hooks/00-hypr-setup-snapshot.hook

    step "Kernel reserva (linux-lts): se uma atualização quebrar o boot, escolha-o no GRUB (Advanced options)"
    sudo pacman -S --needed --noconfirm linux-lts linux-lts-headers linux-headers
    if pacman -Qq nvidia-open &>/dev/null; then
        info "NVIDIA: nvidia-open → nvidia-open-dkms (módulo compilado para os dois kernels)"
        sudo pacman -S --needed --noconfirm --ask=4 nvidia-open-dkms   # --ask=4: aceita remover o conflitante
    fi
    if command -v grub-mkconfig >/dev/null && [[ -f /boot/grub/grub.cfg ]]; then
        # O GRUB ordena os kernels pelo nome e poria o linux-lts como entrada principal
        if grep -q '^#\?GRUB_TOP_LEVEL=' /etc/default/grub; then
            sudo sed -i 's|^#\?GRUB_TOP_LEVEL=.*|GRUB_TOP_LEVEL="/boot/vmlinuz-linux"|' /etc/default/grub
        else
            echo 'GRUB_TOP_LEVEL="/boot/vmlinuz-linux"' | sudo tee -a /etc/default/grub >/dev/null
        fi
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    step "Mirrors do pacman: os mais rápidos (Brasil + EUA), atualizados toda semana"
    sudo pacman -S --needed --noconfirm reflector plocate
    sudo install -Dm644 "$REPO/system/etc/xdg/reflector/reflector.conf" /etc/xdg/reflector/reflector.conf
    sudo systemctl enable reflector.timer plocate-updatedb.timer
    sudo systemctl start plocate-updatedb.service || true

    step "zram (swap comprimida na memória)"
    sudo install -Dm644 "$REPO/system/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
    sudo install -Dm644 "$REPO/system/etc/sysctl.d/99-zram.conf" /etc/sysctl.d/99-zram.conf
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service || warn "zram: ativa no próximo boot"
    sudo sysctl -q --system

    step "Tampa do notebook (com monitor externo não suspende; vale após reiniciar)"
    sudo install -Dm644 "$REPO/system/etc/systemd/logind.conf.d/10-lid.conf" /etc/systemd/logind.conf.d/10-lid.conf

    if grep -qi acer /sys/class/dmi/id/sys_vendor 2>/dev/null && [[ -d /sys/class/power_supply/BAT0 || -d /sys/class/power_supply/BAT1 ]]; then
        step "Limite de carga da bateria em 80% (acer-wmi-battery)"
        sudo install -Dm644 "$REPO/system/etc/modprobe.d/acer-wmi-battery.conf" /etc/modprobe.d/acer-wmi-battery.conf
        if yay -S --needed --noconfirm "${AUR_BATTERY[@]}" && sudo modprobe acer-wmi-battery enable_health_mode=1; then
            info "health_mode = $(cat /sys/bus/wmi/drivers/acer-wmi-battery/health_mode 2>/dev/null || echo '?') (1 = limite de 80% ativo)"
        else
            warn "Limite de bateria não disponível neste modelo/kernel (o resto segue normal)"
        fi
    fi
}

deploy_dotfiles() {
    step "Copiando configs para a home"
    [[ -d $DOTS ]] || { echo "Pasta $DOTS não encontrada." >&2; exit 1; }
    local backup="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)" rel src dst moved=0
    for rel in "${MANAGED[@]}"; do
        src="$DOTS/$rel"; dst="$HOME/$rel"
        [[ -e $src ]] || { warn "faltando no pacote: $rel"; continue; }
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
    if (( moved )); then info "Configs antigas diferentes foram movidas para $backup"; fi

    for rel in "${DEFAULT_WALLS[@]}"; do
        mkdir -p "$HOME/$(dirname "$rel")"
        [[ -e $HOME/$rel ]] || cp -a "$DOTS/$rel" "$HOME/$rel"
    done

    # Pastas pessoais em inglês (Desktop, Documents, Projects, ...)
    local d
    for d in Desktop Documents Downloads Music Pictures Projects Public Templates Videos; do mkdir -p "$HOME/$d"; done
    mkdir -p "$HOME/Pictures/Screenshots"

    # Git: assinatura de commits com a chave SSH (se existir) e agente SSH do gnome-keyring
    if [[ -f $HOME/.ssh/id_ed25519.pub ]]; then
        printf '%s %s\n' "$(git config --get user.email)" "$(cut -d' ' -f1,2 "$HOME/.ssh/id_ed25519.pub")" \
            > "$HOME/.config/git/allowed_signers"
    else
        warn "Sem ~/.ssh/id_ed25519: commits não serão assinados. Crie com: ssh-keygen -t ed25519 (veja README)"
        git config --file "$HOME/.config/git/local" commit.gpgsign false
        git config --file "$HOME/.config/git/local" tag.gpgsign false
    fi
    systemctl --user enable gcr-ssh-agent.socket 2>/dev/null || true

    # Yazi abre pastas
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    if command -v xdg-mime >/dev/null; then xdg-mime default yazi-kitty.desktop inode/directory; fi
}

setup_shell() {
    step "Shell padrão: zsh"
    [[ "$(getent passwd "$USER" | cut -d: -f7)" == /usr/bin/zsh ]] || sudo chsh -s /usr/bin/zsh "$USER"
    if (( INSTALL_CLAUDE_CODE )) && ! command -v claude >/dev/null && [[ ! -x $HOME/.local/bin/claude ]]; then
        step "Claude Code (CLI)"
        curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code falhou (instale depois: https://claude.ai/install.sh)"
    fi
    step "jupytext (notebooks .ipynb no Neovim)"
    uv tool install --quiet jupytext 2>/dev/null || uv tool upgrade --quiet jupytext || warn "jupytext falhou"
}

setup_nvim() {
    step "Neovim: plugins (versões fixadas em lazy-lock.json)"
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true

    step "Neovim: parsers de sintaxe"
    local ts_list mason_list
    ts_list=$(printf '"%s",' "${TS_PARSERS[@]}")
    nvim --headless -c "lua vim.defer_fn(function()
        local ts = require('nvim-treesitter')
        ts.install({${ts_list}}):wait(600000)
        print('parsers: ' .. #ts.get_installed())
        vim.cmd('qa!') end, 1000)" 2>&1 | grep -E '^parsers' || warn "parsers: verifique com :checkhealth"

    step "Neovim: servidores de linguagem e ferramentas (Mason)"
    mason_list=$(printf '"%s",' "${MASON_PKGS[@]}")
    nvim --headless -c 'Lazy load mason.nvim' -c "lua
        local reg = require('mason-registry')
        local pending, failed = 0, {}
        reg.refresh(function()
          for _, name in ipairs({${mason_list}}) do
            local ok, p = pcall(reg.get_package, name)
            if ok and not p:is_installed() then
              pending = pending + 1
              p:install({}, function(success) if not success then table.insert(failed, name) end; pending = pending - 1 end)
            end
          end
          local function wait()
            if pending == 0 then
              print('mason: ' .. #reg.get_installed_package_names() .. ' instalados' .. (#failed > 0 and (' | falharam: ' .. table.concat(failed, ' ')) or ''))
              vim.cmd('qa!')
            else vim.defer_fn(wait, 1000) end
          end
          wait()
        end)" 2>&1 | grep -E '^mason' || warn "mason: verifique com :Mason"
}

save_dotfiles() {
    step "Salvando configs atuais da home em $DOTS"
    local rel src dst ex
    for rel in "${MANAGED[@]}"; do
        src="$HOME/$rel"; dst="$DOTS/$rel"
        [[ -e $src ]] || { warn "não existe na home: $rel"; continue; }
        rm -rf "$dst"
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
    done
    for ex in "${SAVE_EXCLUDE[@]}"; do rm -rf "${DOTS:?}/$ex"; done

    info "Pronto. Tamanho: $(du -sh "$DOTS" | cut -f1)"
}

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; }

# ── Principal ───────────────────────────────────────────────────────────
case "${1:-all}" in
    all)
        need_user
        step "Pedindo a senha do sudo (uma vez só)"
        sudo_keepalive
        setup_pacman
        detect_hardware
        install_packages
        install_aur
        setup_system
        setup_extras
        deploy_dotfiles
        setup_shell
        setup_nvim
        printf '\n\e[1;32mPronto!\e[0m Reinicie (sudo reboot) e entre na sessão "Hyprland".\n'
        printf 'No primeiro login o wallpaper animado é aplicado e as cores são geradas. SUPER + F1 mostra os atalhos.\n'
        ;;
    dotfiles) need_user; deploy_dotfiles ;;
    nvim)     need_user; setup_nvim ;;
    save)     need_user; save_dotfiles ;;
    sddm)     need_user; setup_sddm ;;
    extras)   need_user; sudo_keepalive; setup_extras ;;
    -h|--help|help) usage ;;
    *) usage; exit 1 ;;
esac
