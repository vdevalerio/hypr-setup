#!/usr/bin/env bash
# Hardware health warnings (started at login): CPU and SSD temperature, SSD wear and SMART
# status, free space on /. Warns once per problem; warns again after it clears.
# The SMART summary comes from hypr-setup-smart.timer (root). Never reads the NVIDIA GPU:
# that would wake it and drain the battery.
#   health-watch.sh        loop (run by Hyprland)       health-watch.sh once   a single check
SMART=/var/lib/hypr-setup/smart.json
CPU_WARN=90 CPU_REARM=80 CPU_MINUTES=3    # sustained: short spikes are normal on a laptop
SSD_WARN=70 SSD_CRIT=80 SSD_REARM=60
WEAR_WARN=90
FREE_WARN=90 FREE_CRIT=95 FREE_REARM=85   # % used

declare -A sent        # problems already reported
hot=0                  # consecutive minutes with the CPU above CPU_WARN

hwmon() { local h; for h in /sys/class/hwmon/hwmon*; do [[ $(cat "$h/name" 2>/dev/null) == "$1" ]] && { echo "$h"; return; }; done; return 1; }
temp() { local h; h=$(hwmon "$1") && echo $(( $(cat "$h/temp1_input") / 1000 )); }

# warn <key> <urgency> <title> <body>: once per key
warn() {
    [[ -n ${sent[$1]:-} ]] && return
    sent[$1]=1
    notify-send -a health -u "$2" -i dialog-warning "$3" "$4"
}
clear_key() { unset "sent[$1]"; }

check() {
    local t pct dev
    # CPU
    if t=$(temp k10temp); then
        if (( t >= CPU_WARN )); then (( hot++ )); else (( t <= CPU_REARM )) && { hot=0; clear_key cpu; }; fi
        (( hot >= CPU_MINUTES )) && warn cpu normal "CPU at ${t}°C" "Hot for ${CPU_MINUTES}+ minutes: check the vents, the power profile and what is running (btop)"
    fi
    # SSD temperature
    if t=$(temp nvme); then
        if (( t >= SSD_CRIT )); then warn ssd-hot critical "SSD at ${t}°C" "Dangerously hot: it will throttle; check airflow"
        elif (( t >= SSD_WARN )); then warn ssd-hot normal "SSD at ${t}°C" "Running hot (heavy copy or poor airflow?)"
        elif (( t <= SSD_REARM )); then clear_key ssd-hot; fi
    fi
    # SMART summary (updated every 6 h by root)
    if [[ -r $SMART ]]; then
        while IFS='|' read -r dev model passed used media crit realloc; do
            [[ $passed == false ]] && warn "smart-$dev" critical "Disk failing: $model" "SMART says $dev is failing. Back up now (backup run) and replace it"
            (( crit > 0 )) && warn "crit-$dev" critical "Disk warning: $model" "$dev reports a critical warning flag ($crit). Back up now"
            (( media > 0 )) && warn "media-$dev" normal "Disk errors: $model" "$dev has $media media errors"
            (( realloc > 0 )) && warn "realloc-$dev" normal "Bad sectors: $model" "$dev has $realloc reallocated sectors"
            [[ $used =~ ^[0-9]+$ ]] && (( used >= WEAR_WARN )) && warn "wear-$dev" normal "SSD wear ${used}%" "$model is near the end of its rated life"
        done < <(jq -r '.[] | [.device, .model, .passed, (.used // 0), .media_errors, .critical, .reallocated] | join("|")' "$SMART" 2>/dev/null)
    fi
    # Free space
    pct=$(df --output=pcent / | tail -1 | tr -dc 0-9)
    if (( pct >= FREE_CRIT )); then warn space critical "Disk ${pct}% full" "Only $(df -h --output=avail / | tail -1 | tr -d ' ') left on /"
    elif (( pct >= FREE_WARN )); then warn space normal "Disk ${pct}% full" "Only $(df -h --output=avail / | tail -1 | tr -d ' ') left on /"
    elif (( pct <= FREE_REARM )); then clear_key space; fi
}

if [[ ${1:-} == once ]]; then check; exit 0; fi

SIG=${HYPRLAND_INSTANCE_SIGNATURE:?run inside Hyprland}
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/health-watch-$SIG.lock"
flock -n 9 || exit 0
alive() { [ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/$SIG/.socket.sock" ]; }
while alive; do check; sleep 60; done
