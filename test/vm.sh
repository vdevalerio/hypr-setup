#!/usr/bin/env bash
# Tests hypr-setup from scratch in a VM (QEMU/KVM, UEFI, virgl 3D video), without touching your system.
#
#   test/vm.sh deps        prints the command to install QEMU with 3D video (needs sudo)
#   test/vm.sh iso         downloads the latest Arch ISO and checks the sha256
#   test/vm.sh create      creates the disk (40 GB, grows as used) and the UEFI NVRAM
#   test/vm.sh live        boots the VM from the ISO; the SSH key is added automatically via cloud-init
#   test/vm.sh run         boots the VM from the disk (once installed)
#   test/vm.sh ssh [cmd]   logs into the VM (root on the live ISO, "tester" once installed)
#   test/vm.sh install     installs base Arch over SSH (VM running in "live") — test/arch-base.sh
#   test/vm.sh setup       copies this repository to the VM and runs ./install.sh (log in ~/install.log)
#   test/vm.sh destroy     deletes the VM (disk, NVRAM); the ISO is kept
#
# Files in ~/VMs/hypr-setup-test (outside the repository). The VM: 4 vCPUs, 6 GB, SSH on localhost:2222.

set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR=${VM_DIR:-$HOME/VMs/hypr-setup-test}
ISO=$DIR/archlinux-x86_64.iso
DISK=$DIR/disk.qcow2
VARS=$DIR/OVMF_VARS.4m.fd
KEY=$DIR/id_vm
PORT=2222
SEED_PORT=8735
MIRROR=https://geo.mirror.pkgbuild.com/iso/latest

mkdir -p "$DIR"

deps() {
    # The -gl modules need the base modules (virtio-gpu/-pci/-vga), but the packages don't declare that
    echo "sudo pacman -S --needed qemu-img qemu-ui-gtk qemu-ui-opengl qemu-audio-pipewire \\"
    echo "    qemu-hw-display-virtio-gpu qemu-hw-display-virtio-gpu-pci qemu-hw-display-virtio-vga \\"
    echo "    qemu-hw-display-virtio-gpu-gl qemu-hw-display-virtio-gpu-pci-gl qemu-hw-display-virtio-vga-gl"
}

iso() {
    curl -fL --progress-bar -o "$ISO.part" "$MIRROR/archlinux-x86_64.iso"
    local want
    want=$(curl -fsSL "$MIRROR/sha256sums.txt" | awk '$2 == "archlinux-x86_64.iso" { print $1 }')
    [[ $(sha256sum "$ISO.part" | cut -d' ' -f1) == "$want" ]] || { echo "sha256 mismatch" >&2; exit 1; }
    mv "$ISO.part" "$ISO"
    echo "ISO ok: $ISO"
}

create() {
    [[ -e $DISK ]] && { echo "Already exists: $DISK (run destroy first)" >&2; exit 1; }
    qemu-img create -q -f qcow2 "$DISK" 40G
    cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$VARS"
    [[ -f $KEY ]] || ssh-keygen -q -t ed25519 -N "" -C hypr-setup-vm -f "$KEY"
    echo "Disk and NVRAM created in $DIR"
}

# ISO's cloud-init (NoCloud over HTTP, address passed in the SMBIOS serial number): puts the SSH key on root
seed() {
    mkdir -p "$DIR/seed"
    printf 'instance-id: hypr-setup-vm\nlocal-hostname: archiso\n' > "$DIR/seed/meta-data"
    cat > "$DIR/seed/user-data" <<EOF
#cloud-config
disable_root: false
users:
  - name: root
    ssh_authorized_keys:
      - $(cat "$KEY.pub")
EOF
    : > "$DIR/seed/vendor-data"
    pkill -f "http[.]server $SEED_PORT" 2>/dev/null || true
    (cd "$DIR/seed" && setsid -f python3 -m http.server "$SEED_PORT" --bind 127.0.0.1 >/dev/null 2>&1)
}

qemu() {
    local extra=("$@")
    setsid -f qemu-system-x86_64 -name hypr-setup-test -enable-kvm -machine q35 -cpu host -smp 4 -m 6G \
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
        -drive if=pflash,format=raw,file="$VARS" \
        -drive file="$DISK",if=virtio,discard=unmap \
        -device virtio-vga-gl -display gtk,gl=on,zoom-to-fit=off \
        -netdev user,id=n0,hostfwd=tcp:127.0.0.1:$PORT-:22 -device virtio-net-pci,netdev=n0 \
        -audiodev pipewire,id=a0 -device intel-hda -device hda-duplex,audiodev=a0 \
        -device qemu-xhci -device usb-tablet \
        "${extra[@]}" >"$DIR/qemu.log" 2>&1
}

running() { pgrep -f "qemu-system-x86_64 -name hypr-[s]etup-test" >/dev/null; }

live() {
    [[ -f $ISO ]] || { echo "Missing ISO: test/vm.sh iso" >&2; exit 1; }
    running && { echo "The VM is already running" >&2; exit 1; }
    seed
    qemu -cdrom "$ISO" -boot once=d -smbios "type=1,serial=ds=nocloud;s=http://10.0.2.2:$SEED_PORT/"
    echo "VM booted from the ISO. Waiting for SSH (boot takes ~1 min)..."
    wait_ssh root
}

run() {
    running && { echo "The VM is already running" >&2; exit 1; }
    [[ -f $DISK && -f $VARS ]] || { echo "The VM doesn't exist (test/vm.sh create, live, install)" >&2; exit 1; }
    qemu
    echo "VM booted from the disk."
}

vssh() { # vssh <user> [command...]
    local user=$1; shift
    ssh -i "$KEY" -p "$PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR -o ConnectTimeout=5 "$user@127.0.0.1" "$@"
}

wait_ssh() {
    local i
    for i in $(seq 1 60); do
        vssh "$1" true 2>/dev/null && { echo "SSH ok ($1)"; return 0; }
        sleep 5
    done
    echo "SSH didn't respond within 5 min (check the VM window)" >&2; return 1
}

user_of_vm() { vssh tester true </dev/null 2>/dev/null && echo tester || echo root; }   # </dev/null: doesn't consume the command's stdin

install_base() {
    vssh root "bash -s -- '$(cat "$KEY.pub")'" < "$REPO/test/arch-base.sh"
}

setup() {
    echo "Copying the repository to the VM..."
    tar -C "$(dirname "$REPO")" --exclude='test/*.qcow2' -czf - "$(basename "$REPO")" | vssh tester "tar -xzf - -C ~"
    vssh tester "cd ~/hypr-setup && nohup ./install.sh > ~/install.log 2>&1 < /dev/null & echo PID \$!"
    echo "install.sh running in the VM. Follow along: test/vm.sh ssh tail -f install.log"
}

destroy() {
    running && pkill -f "qemu-system-x86_64 -name hypr-[s]etup-test" || true
    rm -f "$DISK" "$VARS"
    echo "VM deleted (the ISO and key were kept in $DIR)"
}

case "${1:-}" in
    deps) deps ;;
    iso) iso ;;
    create) create ;;
    live) live ;;
    run) run ;;
    ssh) shift; vssh "$(user_of_vm)" "$@" ;;
    install) install_base ;;
    setup) setup ;;
    destroy) destroy ;;
    *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
