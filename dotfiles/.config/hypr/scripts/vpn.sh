#!/usr/bin/env bash
# VPN: WireGuard / OpenVPN connections from NetworkManager, plus Tailscale if installed.
#   vpn.sh status   JSON for Waybar (empty, so the module hides, when no VPN is connected)
#   vpn.sh menu     Rofi list: pick one to connect or disconnect; import a WireGuard .conf
refresh_bar() { pkill -RTMIN+12 -x waybar; }

# "name" lines of the connected VPNs
active() {
    nmcli -t -f NAME,TYPE con show --active 2>/dev/null | awk -F: '$2=="wireguard" || $2=="vpn" {print $1}'
    ts_running && echo Tailscale
}
ts_running() {
    command -v tailscale >/dev/null &&
        [[ $(timeout 3 tailscale status --json 2>/dev/null | jq -r '.BackendState // empty') == Running ]]
}

case "${1:-status}" in
status)
    names=$(active | paste -sd, | sed 's/,/, /g')
    if [[ -z $names ]]; then
        jq -cn '{text: "", tooltip: "", class: "off"}'
    else
        jq -cn --arg t "$names" --arg i $'\U000F0582' '{text: $i, tooltip: ("VPN: " + $t + "\n\nClick: manage"), class: "on"}'
    fi ;;
menu)
    on=$(active)
    items=(); acts=()
    while IFS=: read -r name type; do
        [[ $type == wireguard || $type == vpn ]] || continue
        if grep -qxF "$name" <<<"$on"; then items+=("󰌾  $name  (connected)"); acts+=("down|$name")
        else items+=("󰌿  $name"); acts+=("up|$name"); fi
    done < <(nmcli -t -f NAME,TYPE con show)
    if command -v tailscale >/dev/null; then
        if grep -qxF Tailscale <<<"$on"; then items+=("󰌾  Tailscale  (connected)"); acts+=("ts-down|")
        else items+=("󰌿  Tailscale"); acts+=("ts-up|"); fi
    fi
    items+=("󰐕  Import a WireGuard config…"); acts+=("import|")
    idx=$(printf '%s\n' "${items[@]}" | rofi -dmenu -i -no-custom -format i -p VPN) || exit 0
    [[ -n $idx ]] || exit 0
    IFS='|' read -r act name <<<"${acts[idx]}"
    case $act in
    up)   nmcli con up id "$name" >/dev/null 2>&1 && notify-send -a vpn -i network-vpn "VPN" "Connected: $name" \
              || notify-send -a vpn -u critical -i network-vpn-disconnected "VPN" "Could not connect: $name" ;;
    down) nmcli con down id "$name" >/dev/null 2>&1 && notify-send -a vpn -i network-vpn-disconnected "VPN" "Disconnected: $name" ;;
    ts-up)
        if url=$(timeout 20 tailscale up 2>&1 | grep -o 'https://login[^ ]*' | head -1) && [[ -n $url ]]; then
            notify-send -a vpn -i network-vpn "Tailscale" "Sign in: $url"; xdg-open "$url" >/dev/null 2>&1
        else notify-send -a vpn -i network-vpn "Tailscale" "Connected"; fi ;;
    ts-down) tailscale down && notify-send -a vpn -i network-vpn-disconnected "Tailscale" "Disconnected" ;;
    import)
        f=$(rofi -dmenu -no-custom -lines 0 -p "Path to the .conf (e.g. ~/Downloads/wg0.conf)" </dev/null) || exit 0
        f=${f/#\~/$HOME}
        [[ -f $f ]] || { notify-send -a vpn -u critical "VPN" "File not found: $f"; exit 1; }
        if nmcli con import type wireguard file "$f" >/dev/null 2>&1; then
            notify-send -a vpn -i network-vpn "VPN" "Imported: ${f##*/}"
        else notify-send -a vpn -u critical "VPN" "Import failed (is it a WireGuard .conf?)"; fi ;;
    esac
    refresh_bar ;;
*)  sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
