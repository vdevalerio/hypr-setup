#!/usr/bin/env bash
# Starts Waybar and restarts it if it crashes. Closing it on purpose (pkill waybar) ends the loop.
# Tied to the Hyprland session that started it: when that session ends (logout), bar.sh exits too, and
# the lock is per session, so a new session never ends up without a bar because of an old one.
SIG=${HYPRLAND_INSTANCE_SIGNATURE:?run inside Hyprland}
alive() { [ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/$SIG/.socket.sock" ]; }

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/bar-$SIG.lock"
flock -n 9 || exit 0                       # a bar.sh is already running in this session
while alive; do
    start=$(date +%s)
    waybar 9>&-
    code=$?
    [ "$code" -eq 0 ] && exit 0            # exited normally (pkill/SIGTERM)
    alive || exit 0                        # the session ended: don't restart
    notify-send -a waybar -u low "Bar" "Waybar crashed (exit $code) and was restarted"
    (( $(date +%s) - start < 5 )) && sleep 3   # crashing right away: wait a bit
done
