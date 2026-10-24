#!/usr/bin/env bash
# Arch base mínimo na VM de teste (roda como root no live ISO; chamado por test/vm.sh install).
# Faz o que uma instalação "normal" deixaria pronto antes do ./install.sh: UEFI + GRUB, ext4,
# usuário "tester" (senha "tester", sudo sem senha — só nesta VM), rede, SSH e git.
#   bash -s -- "<chave pública ssh>"   < arch-base.sh
set -euo pipefail
PUBKEY=${1:?chave pública}
DISK=/dev/vda

echo "==> Esperando o relógio e as chaves do pacman"
timedatectl set-ntp true
systemctl is-active --quiet pacman-init.service || systemctl start pacman-init.service
for _ in $(seq 1 60); do systemctl is-active --quiet pacman-init.service && break; sleep 2; done

echo "==> Particionando $DISK (ESP 1 GB em /boot + raiz ext4)"
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

echo "==> Configurando o sistema"
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
# O firewall do install.sh bloqueia conexões de entrada: libera o SSH só nesta VM de teste
install -d /etc/nftables.d/input
echo 'tcp dport 22 accept' > /etc/nftables.d/input/ssh.nft
EOF

umount -R /mnt
echo "==> Arch base pronto. Desligue a VM e ligue pelo disco (test/vm.sh run)."
