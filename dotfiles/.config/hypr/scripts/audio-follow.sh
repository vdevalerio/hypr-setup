#!/usr/bin/env bash
# Started at login: when a Bluetooth headset connects, make its sink the default so the
# bar and volume keys control it (WirePlumber keeps a previously chosen default otherwise).
SIG=${HYPRLAND_INSTANCE_SIGNATURE:?run inside Hyprland}
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/audio-follow-$SIG.lock"
flock -n 9 || exit 0

pactl subscribe | while read -r _ ev _ kind _; do
    [ "$ev" = "'new'" ] && [ "$kind" = sink ] || continue
    sleep 1   # the sink is usable a moment after the event
    sink=$(pactl list short sinks | awk '$2 ~ /^bluez_output/ {print $2; exit}')
    [ -n "$sink" ] && pactl set-default-sink "$sink"
done
