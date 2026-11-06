#!/usr/bin/env bash
# Lock screen, two flavours:
#   lock.sh            automatic lock (hypridle / loginctl lock-session): uses the default mode
#   lock.sh normal     today's behaviour: the system may idle-suspend / suspend on lid close
#   lock.sh remote     remote-safe: same lock screen (password required) but the system stays awake:
#                      a systemd inhibitor (sleep, idle, lid switch) lives only while the screen is locked,
#                      so SSH / Claude Code remote sessions and jobs keep running
#   lock.sh default [normal|remote]   shows / sets the mode used by the automatic lock (idle timeout)
state=${XDG_STATE_HOME:-$HOME/.local/state}/hypr-lock-mode
mode_default() { cat "$state" 2>/dev/null || echo normal; }

case "${1:-auto}" in
    default)
        if [[ ${2:-} =~ ^(normal|remote)$ ]]; then
            mkdir -p "${state%/*}"; echo "$2" >"$state"
            notify-send -a lock "Automatic lock: $2"
        else mode_default; fi
        exit 0 ;;
    normal | remote) mode=$1 ;;
    auto) mode=$(mode_default) ;;
    *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac

pidof hyprlock >/dev/null && exit 0
pgrep -f "quickshell/[l]ock.qml" >/dev/null && exit 0

run=()
if [[ $mode == remote ]]; then
    run=(systemd-inhibit --what=sleep:idle:handle-lid-switch --who=hypr-lock --mode=block
        --why="Remote-safe lock: keep the system awake")
fi

if command -v qs >/dev/null && [ -f ~/.config/quickshell/lock.qml ]; then
    "${run[@]}" qs -p ~/.config/quickshell/lock.qml && exit 0
fi
exec "${run[@]}" hyprlock
