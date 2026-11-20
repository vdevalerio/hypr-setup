#!/usr/bin/env bash
# Which GPU renders the desktop (Hyprland) on this hybrid laptop. Applies at the next login.
#   gpu.sh status          current setting and the GPU in use right now
#   gpu.sh dgpu            dedicated GPU (NVIDIA): smoother under heavy load, more power draw
#   gpu.sh igpu            integrated GPU: saves battery, the NVIDIA GPU stays for `prime-run <app>`
CONF=~/.config/hypr/gpu.conf
mode() { sed -n 's/^GPU=//p' "$CONF" 2>/dev/null | tail -1; }
case ${1:-status} in
dgpu | igpu)
    printf '# Which GPU renders the desktop (changed by scripts/gpu.sh; applies at the next login)\nGPU=%s\n' "$1" >"$CONF"
    echo "Desktop GPU: $1 (log out and back in to apply)"
    command -v notify-send >/dev/null && notify-send -a gpu -u low "Desktop GPU: $1" "Applies at the next login"
    ;;
status)
    echo "configured: $(mode || true)"
    echo "renderer:    $(tr '\0' '\n' <"/proc/$(pgrep -x Hyprland | head -1)/environ" 2>/dev/null | sed -n 's/^AQ_DRM_DEVICES=//p')  (first = renders)"
    ;;
*) echo "usage: gpu.sh status|dgpu|igpu" >&2; exit 2 ;;
esac
