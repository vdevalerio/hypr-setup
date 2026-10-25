#!/usr/bin/env bash
# Minimal base Arch in the test VM (runs as root on the live ISO; called by test/vm.sh install).
# Does what a "normal" install would leave ready before ./install.sh: UEFI + GRUB, ext4,
# user "tester" (password "tester", passwordless sudo — this VM only), network, SSH and git.
#   bash -s -- "<ssh public key>"   < arch-base.sh
set -euo pipefail
PUBKEY=${1:?public key}
DISK=/dev/vda

echo "==> Waiting for the clock and pacman keys"
timedatectl set-ntp true
systemctl is-active --quiet pacman-init.service || systemctl start pacman-init.service
for _ in $(seq 1 60); do systemctl is-active --quiet pacman-init.service && break; sleep 2; done

echo "==> Partitioning $DISK (1 GB ESP at /boot + ext4 root)"
sgdisk --zap-all "$DISK" >/dev/null
sgdisk -n1:0:+1G -t1:ef00 -c1:EFI -n2:0:0 -t2:8300 -c2:root "$DISK" >/dev/null
partprobe "$DISK"; sleep 1
mkfs.fat -F32 -n EFI "${DISK}1" >/dev/null
mkfs.ext4 -q -F -L root "${DISK}2"
mount "${DISK}2" /mnt
mount --mkdir "${DISK}1" /mnt/boot

echo "==> pacstrap"
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
pacstrap -K /mnt base linux linux-firmware amd-ucode intel-ucode grub efibootmgr \
    networkmanager openssh sudo git nano >/dev/null
genfstab -U /mnt >> /mnt/etc/fstab

echo "==> Configuring the system"
arch-chroot /mnt /bin/bash -e <<EOF
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen >/dev/null
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=br-abnt2 > /etc/vconsole.conf
echo hyprvm > /etc/hostname
useradd -m -G wheel -s /bin/bash tester
echo tester:tester | chpasswd
echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-wheel-nopasswd
chmod 440 /etc/sudoers.d/10-wheel-nopasswd
install -d -m700 -o tester -g tester /home/tester/.ssh
echo '$PUBKEY' > /home/tester/.ssh/authorized_keys
chown tester:tester /home/tester/.ssh/authorized_keys; chmod 600 /home/tester/.ssh/authorized_keys
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable >/dev/null 2>&1
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
systemctl enable NetworkManager sshd >/dev/null 2>&1
# install.sh's firewall blocks inbound connections: allow SSH on this test VM only
install -d /etc/nftables.d/input
echo 'tcp dport 22 accept' > /etc/nftables.d/input/ssh.nft
EOF

umount -R /mnt
echo "==> Base Arch ready. Shut down the VM and boot from the disk (test/vm.sh run)."
