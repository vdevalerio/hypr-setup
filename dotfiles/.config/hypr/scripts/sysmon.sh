#!/usr/bin/env bash
# Ilha de monitoramento da Waybar: GPU e temperaturas (CPU, memória e disco usam os módulos nativos).
#   sysmon.sh gpu    (contínuo) uso da GPU mais ocupada; tooltip com cada placa (uso, temperatura, VRAM, consumo)
#   sysmon.sh temp   temperatura da CPU; tooltip com todos os sensores
#   sysmon.sh top    abre o btop numa janela flutuante
# A NVIDIA só é consultada se já estiver acordada (D0): o nvidia-smi tiraria a placa do modo de
# economia (RTD3) a cada leitura.
WARN=75 CRIT=90   # °C
UWARN=85 UCRIT=98 # % de uso da GPU (a iGPU passa de 60% só compondo a tela com wallpaper em vídeo)
declare -A AMD_BUSY   # uso médio da iGPU por placa (preenchido pelo modo gpu)

hwmon_by_name() {   # caminho do hwmon com esse nome (k10temp, coretemp, amdgpu, nvme...)
    local h
    for h in /sys/class/hwmon/hwmon*; do
        [[ $(<"$h/name") == "$1" ]] 2>/dev/null && { echo "$h"; return 0; }
    done
    return 1
}

milli() { local v; v=$(<"$1") 2>/dev/null && echo $(( v / 1000 )); }   # m°C → °C

cpu_temp() {
    local h
    for name in k10temp zenpower coretemp; do
        h=$(hwmon_by_name "$name") && { milli "$h/temp1_input"; return; }
    done
    h=/sys/class/thermal/thermal_zone0/temp; [[ -r $h ]] && milli "$h"
}

klass() {   # valor, alerta, crítico → classe CSS
    (( $1 >= $3 )) && echo critical && return
    (( $1 >= $2 )) && echo warning && return
    echo normal
}

json() {   # texto, tooltip, classe, porcentagem
    jq -cn --arg t "$1" --arg tt "$2" --arg c "$3" --argjson p "${4:-0}" \
        '{text: $t, tooltip: $tt, class: $c, percentage: $p}'
}

# Placas de vídeo: uma linha "nome|uso|temp|vram_usada_MiB|vram_total_MiB|watts" por placa
gpus() {
    local card dev vendor used total temp busy h w
    for card in /sys/class/drm/card[0-9]; do
        dev=$card/device; vendor=$(<"$dev/vendor") 2>/dev/null || continue
        case $vendor in
        0x1002)   # AMD (amdgpu)
            [[ -r $dev/gpu_busy_percent ]] || continue
            busy=${AMD_BUSY[$card]:-$(<"$dev/gpu_busy_percent")}
            used=$(( $(<"$dev/mem_info_vram_used") / 1048576 ))
            total=$(( $(<"$dev/mem_info_vram_total") / 1048576 ))
            h=$(echo "$dev"/hwmon/hwmon*)
            temp=$(milli "$h/temp1_input")
            w=$(<"$h/power1_input") 2>/dev/null || w=$(<"$h/power1_average") 2>/dev/null || w=
            [[ -n $w ]] && w=$(awk "BEGIN{printf \"%.1f W (whole chip)\", $w/1000000}")
            echo "AMD Radeon|$busy|${temp:-?}|$used|$total|$w" ;;
        0x10de)   # NVIDIA
            if [[ $(<"$dev/power/runtime_status") != active ]] 2>/dev/null; then
                echo "NVIDIA|off|||||"; continue
            fi
            command -v nvidia-smi >/dev/null || continue
            nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw \
                --format=csv,noheader,nounits 2>/dev/null |
                awk -F', *' '{sub(/^NVIDIA GeForce /, "", $1); sub(/ Laptop GPU$/, "", $1);
                              printf "%s|%s|%s|%s|%s|%.1f W\n", $1, $2, $3, $4, $5, $6}' ;;
        esac
    done
}

case ${1:-} in
gpu)   # contínuo: a leitura da iGPU oscila entre 0 e 100 → amostra a cada 0,1 s, publica a média a cada 3 s
    declare -A sum
    amd=()
    for card in /sys/class/drm/card[0-9]; do [[ -r $card/device/gpu_busy_percent ]] && amd+=("$card"); done
    exec {tick}<> <(:)   # `read -t` nesse fd espera sem criar processo (sleep custaria um fork por amostra)
    while :; do
        sum=()
        for (( i = 0; i < 30; i++ )); do
            for card in "${amd[@]}"; do sum[$card]=$(( ${sum[$card]:-0} + $(<"$card/device/gpu_busy_percent") )); done
            read -rt 0.1 -u "$tick"
        done
        for card in "${amd[@]}"; do AMD_BUSY[$card]=$(( sum[$card] / 30 )); done

        max=0 maxtemp=0 tip=""
        while IFS='|' read -r name busy temp used total w; do
            if [[ $busy == off ]]; then
                tip+="${tip:+\n}$name: asleep (power saving)"; continue
            fi
            (( busy > max )) && max=$busy
            [[ $temp =~ ^[0-9]+$ ]] && (( temp > maxtemp )) && maxtemp=$temp
            tip+="${tip:+\n}<b>$name</b>  $busy%  ·  ${temp}°C  ·  VRAM ${used}/${total} MiB${w:+  ·  $w}"
        done < <(gpus)
        if [[ -z $tip ]]; then
            json "" "" hidden 0 || exit   # Waybar fechou o pipe: sai
            continue
        fi
        c=$(klass "$max" $UWARN $UCRIT)
        [[ $(klass "$maxtemp" $WARN $CRIT) == critical ]] && c=critical
        json "$max%" "$(printf '%b' "$tip\n\nClick: btop")" "$c" "$max" || exit
    done ;;
temp)
    t=$(cpu_temp); t=${t:-0}
    tip="<b>CPU</b>  ${t}°C"
    while IFS='|' read -r name busy temp _; do
        [[ $temp =~ ^[0-9]+$ ]] && tip+="\n<b>$name</b>  ${temp}°C"
    done < <(gpus)
    h=$(hwmon_by_name nvme) && tip+="\n<b>NVMe</b>  $(milli "$h/temp1_input")°C"
    json "${t}°" "$(printf '%b' "$tip\n\nClick: btop")" "$(klass "$t" $WARN $CRIT)" "$t" ;;
top)
    pgrep -x btop >/dev/null && exec hyprctl dispatch 'hl.dsp.focus({ window = "class:btop-float" })'
    exec kitty --class btop-float -e btop ;;   # tamanho: regra btop-size (rules.lua)
*)  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
