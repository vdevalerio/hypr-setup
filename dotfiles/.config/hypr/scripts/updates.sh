#!/usr/bin/env bash
# Pending updates on the bar (official repos + AUR): refreshed every 30 min and after an update.
#   updates.sh status   JSON for Waybar (empty, so the module hides, when everything is up to date)
#   updates.sh run      opens the update (same as the `update` command) and refreshes the bar
ICON=$'\U000F06B0'                   # nf-md-update
CACHE=~/.cache/updates-pending     # one "name old -> new" line per package

case "${1:-status}" in
status)
    # checkupdates exits 2 when nothing is pending; yay -Qua exits 1. Anything else is a failure
    # (no network): keep showing the last known list instead of hiding the module.
    ok=0; list=""
    out=$(timeout 90 checkupdates 2>/dev/null); rc=$?
    [[ $rc -eq 0 || $rc -eq 2 ]] && { ok=1; list=$out; }
    if [[ $ok -eq 1 ]] && command -v yay >/dev/null; then
        aur=$(timeout 60 yay -Qua 2>/dev/null) && list+=$'\n'$aur
    fi
    if [[ $ok -eq 1 ]]; then
        printf '%s\n' "$list" | sed '/^$/d' > "$CACHE"
    fi
    n=$(grep -c . "$CACHE" 2>/dev/null); n=${n:-0}
    if (( n == 0 )); then
        jq -cn '{text: "", tooltip: "", class: "none"}'
    else
        tip=$(head -n 15 "$CACHE"; (( n > 15 )) && echo "… and $((n - 15)) more")
        klass=pending; (( n >= 50 )) && klass=many
        jq -cn --arg t "$ICON $n" --arg tt "$n updates pending"$'\n\n'"$tip"$'\n\nClick: update' --arg c "$klass" \
            '{text: $t, tooltip: $tt, class: $c}'
    fi ;;
run)
    kitty --class btop-float -e bash -c "$HOME/.config/hypr/scripts/update.sh; pkill -RTMIN+11 -x waybar" ;;
*)  sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
