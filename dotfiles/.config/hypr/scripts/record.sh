#!/usr/bin/env bash
# Screen recording (gpu-screen-recorder: uses the GPU, barely any load). Videos in ~/Videos/Recordings.
#   record.sh screen [mic]   records the focused monitor (with system sound; "mic" adds the microphone)
#   record.sh region [mic]   pick an area with the mouse
#   record.sh stop           stops and saves     · record.sh toggle  (stops if recording, otherwise screen)
#   record.sh status         JSON for Waybar's custom/recording module (only shown while recording)
DIR="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Recordings"
STATE="${XDG_RUNTIME_DIR:-/tmp}/recording"   # PID and file of the recording in progress
mkdir -p "$DIR"

recording() { [ -f "$STATE.pid" ] && kill -0 "$(cat "$STATE.pid")" 2>/dev/null; }
bar() { pkill -RTMIN+10 -x waybar 2>/dev/null; }

start() { # start <screen|region> [mic]
    recording && { stop; return; }
    local target audio="default_output" file
    [ "${2:-}" = mic ] && audio="default_output|default_input"
    file="$DIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"
    if [ "$1" = region ]; then
        local geom; geom=$(slurp -d -b 1e1e2e88 -c cba6f7ff -w 2 -f '%wx%h+%x+%y') || exit 0
        target=(-w region -region "$geom")
    else
        target=(-w "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')")
    fi
    setsid -f gpu-screen-recorder "${target[@]}" -f 60 -a "$audio" -o "$file" </dev/null >"$STATE.log" 2>&1
    sleep 0.5
    pgrep -nf "gpu-screen-recorder .*-o $file" > "$STATE.pid"
    echo "$file" > "$STATE.file"
    if recording; then
        notify-send -a recorder -t 2000 "󰑋  Recording" "SUPER + ALT + R to stop"
    else
        notify-send -a recorder -u critical "Recording failed" "$(tail -3 "$STATE.log")"
        rm -f "$STATE.pid"
    fi
    bar
}

stop() {
    recording || return 0
    kill -INT "$(cat "$STATE.pid")"
    for _ in $(seq 50); do recording || break; sleep 0.1; done
    rm -f "$STATE.pid"
    bar
    local file; file=$(cat "$STATE.file" 2>/dev/null)
    local action
    action=$(notify-send -a recorder -A "open=Open" -A "folder=Show in folder" "Recording saved" "$(basename "$file")")
    case "$action" in
        open)   xdg-open "$file" ;;
        folder) kitty --class yazi -e yazi "$file" ;;
    esac
}

status() {
    if recording; then
        local s=$(( $(date +%s) - $(stat -c %Y "$STATE.pid") ))
        printf '{"text": "󰑋 %d:%02d", "tooltip": "Recording — click to stop", "class": "recording"}\n' $((s / 60)) $((s % 60))
    else
        echo '{"text": ""}'
    fi
}

case "${1:-}" in
    screen) start screen "${2:-}" ;;
    region) start region "${2:-}" ;;
    stop)   stop ;;
    toggle) if recording; then stop; else start screen; fi ;;
    status) status ;;
    *) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
