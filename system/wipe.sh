#!/usr/bin/env bash
# Factory reset: turns the machine back into a bare Arch Linux (called by `./install.sh wipe`).
#   wipe.sh --plan <user>   read-only: shows what would be removed (any user)
#   wipe.sh <user>          DESTRUCTIVE, as root: runs detached (systemd-run) because it kills <user>'s session
#
# Removes: every package outside KEEP (+ orphans), what install.sh wrote to /etc, /usr, /boot, /var,
# the user and its home, logs, journal, caches, shell histories, saved Wi-Fi networks, Bluetooth pairings.
# Keeps: the bootloader, the kernel + firmware, NetworkManager, sshd, sudo, nano, hostname, locale, root.
set -uo pipefail

KEEP=(base linux linux-firmware amd-ucode intel-ucode grub efibootmgr networkmanager openssh sudo nano)

# The root filesystem tools are part of "boots and repairs itself"
case "$(findmnt -no FSTYPE / 2>/dev/null)" in
    btrfs) KEEP+=(btrfs-progs) ;;
    xfs)   KEEP+=(xfsprogs) ;;
    f2fs)  KEEP+=(f2fs-tools) ;;
esac
[[ -d /sys/firmware/efi ]] && KEEP+=(dosfstools)

installed_keep() { # KEEP ∩ installed
    local p
    for p in "${KEEP[@]}"; do pacman -Qq "$p" &>/dev/null && echo "$p"; done
}

if [[ ${1:-} == --plan ]]; then
    user=${2:?user}
    mapfile -t keep < <(installed_keep)
    echo "User deleted:        $user (uid $(id -u "$user" 2>/dev/null || echo '?'), home $(getent passwd "$user" | cut -d: -f6))"
    echo "Packages kept:       ${keep[*]}"
    echo "Explicit packages unmarked (they, and every dependency nothing else needs, are removed):"
    pacman -Qqe | grep -vxFf <(printf '%s\n' "${keep[@]}") | column -c "${COLUMNS:-100}" | sed 's/^/    /'
    echo "Total installed now: $(pacman -Qq | wc -l)"
    exit 0
fi

[[ $EUID -eq 0 ]] || { echo "must run as root" >&2; exit 1; }
user=${1:?user}
uid=$(id -u "$user") || exit 1
home=$(getent passwd "$user" | cut -d: -f6)
((uid >= 1000)) || { echo "refusing to delete uid $uid (< 1000)" >&2; exit 1; }
[[ -n $home && $home != / ]] || { echo "refusing: bad home '$home'" >&2; exit 1; }

LOG=/root/hypr-setup-wipe.log
exec > >(tee -a "$LOG") 2>&1
step() { printf '\n==> %s\n' "$*"; }
try()  { "$@" || echo "  (failed, continuing: $*)"; }
die()  { echo "ABORTED: $*" >&2; exit 1; }

step "Wipe started $(date -Is) — user $user (uid $uid), home $home"

step "Stopping the desktop and ending $user's sessions"
try systemctl stop sddm.service
try loginctl terminate-user "$user"
sleep 2
try pkill -KILL -u "$user"
sleep 1

step "Removing what hypr-setup installed outside packages (hooks first: they run on every pacman transaction)"
rm -f /etc/pacman.d/hooks/00-hypr-setup-snapshot.hook
for u in nftables.service fstrim.timer paccache.timer fwupd-refresh.timer hypr-setup-smart.timer tailscaled.service \
         reflector.timer plocate-updatedb.timer docker.socket docker.service bluetooth.service \
         power-profiles-daemon.service sddm.service nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service; do
    systemctl disable "$u" &>/dev/null
done
rm -rf /usr/local/bin/hypr-setup-* /etc/systemd/system/hypr-setup-* /etc/timeshift /etc/nftables.d \
    /etc/udev/rules.d/80-nvidia-pm.rules /etc/udev/rules.d/90-gpu-symlinks.rules \
    /etc/modprobe.d/nvidia-pm.conf /etc/modprobe.d/acer-wmi-battery.conf /etc/modules-load.d/i2c-dev.conf \
    /etc/systemd/zram-generator.conf /etc/sysctl.d/99-zram.conf /etc/systemd/logind.conf.d/10-lid.conf \
    /etc/xdg/reflector /etc/sddm.conf.d /usr/share/sddm /usr/share/plymouth/themes/hypr-setup \
    /boot/grub/themes/hypr-setup /var/backups/hypr-setup /var/lib/hypr-setup /timeshift
grep -l -w -- "$user" /etc/sudoers.d/* 2>/dev/null | xargs -r rm -f
systemctl daemon-reload

step "Reverting the config edits (GRUB, initramfs, pacman)"
if [[ -f /etc/default/grub ]]; then
    sed -i -e '/^GRUB_TOP_LEVEL=/d' -e '/^GRUB_THEME=/d' -e '/^GRUB_DISABLE_BOOTNEXT=/d' \
        -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' -e 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' \
        -e '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/ \?\bsplash\b//' /etc/default/grub
fi
sed -i -E '/^HOOKS=/ s/ plymouth\b//' /etc/mkinitcpio.conf
sed -i '/^\[multilib\]/,/^Include/ s/^\([^#]\)/#\1/' /etc/pacman.conf

step "Packages: everything outside the base set goes"
# Keep = KEEP plus its hard-dependency closure (pactree resolves providers). Orphan detection alone
# (pacman -Qdtt) leaves dependency cycles behind (pipewire, ffmpeg, qt...), so remove the complement.
pacman -S --needed --noconfirm pacman-contrib >/dev/null || die "cannot install pacman-contrib (network?); nothing removed yet"
mapfile -t keep < <(installed_keep)
mapfile -t closure < <(for p in "${keep[@]}"; do pactree -u "$p"; done | sort -u)
mapfile -t doomed < <(pacman -Qq | grep -vxFf <(printf '%s\n' "${closure[@]}"))
echo "  keeping ${#closure[@]} packages, removing ${#doomed[@]} (of $(pacman -Qq | wc -l))"
((${#closure[@]} > 50)) || die "closure looks wrong (${#closure[@]} packages); nothing removed yet"
pacman -D --asexplicit "${keep[@]}" >/dev/null
# pactree can miss versioned/virtual providers: dry-run the removal (-p) and protect whatever pacman says breaks
protect=()
for _ in $(seq 1 80); do
    mapfile -t rm_list < <(printf '%s\n' "${doomed[@]}" | grep -vxFf <(printf '%s\n' "${protect[@]}" _none_))
    out=$(pacman -R -p --noconfirm "${rm_list[@]}" 2>&1) && break
    mapfile -t more < <(grep -oP 'removing \K\S+(?= breaks dependency)' <<<"$out" | sort -u)
    ((${#more[@]})) || { echo "$out" | tail -5; die "cannot resolve the removal; user and data untouched"; }
    protect+=("${more[@]}")
done
echo "  protected beyond the closure: ${#protect[@]} · removing ${#rm_list[@]}"
((${#rm_list[@]})) && { pacman -Rn --noconfirm "${rm_list[@]}" || die "pacman -Rn failed; user and data untouched"; }
echo "  packages left: $(pacman -Qq | wc -l)"
find /etc/systemd/system /usr/lib/systemd/system -xtype l -delete 2>/dev/null
rm -f /etc/pacman.d/gnupg/S.* 2>/dev/null

step "Deleting the user $user"
try userdel -rf "$user"
getent group "$user" &>/dev/null && try groupdel "$user"
groupdel docker &>/dev/null
rm -rf "$home" "/var/spool/mail/$user" "/var/lib/AccountsService/users/$user" "/var/lib/systemd/linger/$user"
find / -xdev -uid "$uid" -depth -delete 2>/dev/null   # anything it owned elsewhere

step "Rebuilding initramfs and the GRUB menu"
try mkinitcpio -P
[[ -f /boot/grub/grub.cfg ]] && try grub-mkconfig -o /boot/grub/grub.cfg

step "Wiping history, logs, caches and personal state"
journalctl --rotate &>/dev/null; journalctl --vacuum-time=1s &>/dev/null
rm -rf /var/log/journal/* /var/lib/systemd/coredump/* /var/lib/systemd/timers/*
find /var/log -type f -delete
pacman -Scc --noconfirm &>/dev/null; rm -rf /var/cache/* /var/tmp/* /tmp/* 2>/dev/null
rm -rf /etc/NetworkManager/system-connections/* /var/lib/NetworkManager/* /var/lib/bluetooth/* /var/lib/iwd/* \
    /var/lib/tailscale /var/lib/docker /var/lib/containerd /var/lib/postgres /var/lib/plocate /var/lib/fwupd /var/lib/reflector
rm -rf /root/.cache /root/.local /root/.config /root/.ssh /root/.gnupg /root/.claude /root/.lesshst /root/.viminfo /root/.*_history
rm -f /var/log/pacman.log
sync

step "Done $(date -Is) — finishing (reboot) into the bare system (log kept at $LOG)"
sleep 3
systemctl "${WIPE_END:-reboot}"   # WIPE_END=poweroff lets the VM test know when it is really over
