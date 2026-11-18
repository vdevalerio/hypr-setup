#!/bin/sh
# profile.sh get | set <performance|balanced|power-saver>
# Power profile (power-profiles-daemon: CPU) + GPU side (hypr-gpu-profile: iGPU clocks, dGPU power, Dynamic Boost).
case "$1" in
get) powerprofilesctl get ;;
set)
    powerprofilesctl set "$2" || exit 1
    sudo -n /usr/local/bin/hypr-gpu-profile "$2" 2>/dev/null || true   # not installed yet: CPU profile only
    ;;
*) echo "usage: profile.sh get|set <performance|balanced|power-saver>" >&2; exit 2 ;;
esac
