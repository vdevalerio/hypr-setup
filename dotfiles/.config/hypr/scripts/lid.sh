#!/usr/bin/env bash
# Laptop lid with an external monitor ("clamshell"). Called by Hyprland (binds.lua):
#   lid.sh close   lid closed: with another monitor, turns off only the laptop screen
#                  (without an external monitor systemd acts: suspends)
#   lid.sh open    lid open: turns the laptop screen back on
#   lid.sh check   at login and when a monitor is disconnected, if the lid is closed
# Writes nothing to monitors.conf: it only lasts while the lid is closed.
internal=$(hyprctl monitors all -j | jq -r '[.[] | select(.name | test("^(eDP|LVDS|DSI)"))][0].name // empty')
[ -n "$internal" ] || exit 0
desc=$(hyprctl monitors all -j | jq -r --arg n "$internal" '.[] | select(.name == $n) | .description' | sed 's/[[:space:]]*$//')
others() { hyprctl monitors -j | jq --arg n "$internal" '[.[] | select(.name != $n)] | length'; }
lid_closed() { grep -qs closed /proc/acpi/button/lid/*/state; }

close() {
    (( $(others) > 0 )) || return 0
    # by description: takes priority over name-based rules (Displays settings are by description)
    hyprctl eval "hl.monitor({ output = 'desc:$desc', disabled = true })" >/dev/null
}

open() {
    # Reloading the config turns the screen back on with the Displays settings (a new rule on top of
    # the "disabled" one isn't enough for Hyprland to re-enable the monitor). Workspaces come back on their own.
    hyprctl reload >/dev/null
    sleep 0.8
    hyprctl eval 'require("workspaces").setup()' >/dev/null
}

case "${1:-}" in
    close) close ;;
    open)  open ;;
    check)
        # Only with the lid closed (opening the lid already calls "open" via the Hyprland event):
        # with an external monitor, keeps the laptop screen off; with none, turns it back on.
        lid_closed || exit 0
        if (( $(others) > 0 )); then close
        elif [ "$(hyprctl monitors -j | jq --arg n "$internal" 'any(.[]; .name == $n)')" = false ]; then open
        fi ;;
    *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
