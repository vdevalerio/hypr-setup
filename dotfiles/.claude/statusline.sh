#!/usr/bin/env bash
# Claude Code status line (managed by ~/hypr-setup, installed with `./install.sh claude`).
#   <model> · <context bar> <used>k/<window>k · $<session cost> · 5h <rate %> · <dir> <git branch>
# Context color: green < 40%, yellow < 70%, red above — /clear or /compact before it gets red.
# Also caches the subscription rate limits for the Waybar chip (scripts/claude-usage.py).
in=$(cat)
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/claude
mkdir -p "$CACHE"

IFS=$'\t' read -r model pct size cost five five_reset week dir <<<"$(jq -r '[
    (.model.display_name // .model.id // "?"),
    (.context_window.used_percentage // 0),
    (.context_window.context_window_size // 200000),
    (.cost.total_cost_usd // 0),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.workspace.current_dir // .cwd // "")
] | @tsv' <<<"$in")"

# Rate limits for the bar (only subscribers get them; keep the last known values)
if [[ -n $five ]]; then
    jq -n --argjson f "$five" --arg r "$five_reset" --arg w "$week" --argjson t "$(date +%s)" \
        '{five_hour: $f, resets_at: $r, seven_day: ($w | tonumber? // null), updated: $t}' \
        > "$CACHE/ratelimits.json.tmp" && mv "$CACHE/ratelimits.json.tmp" "$CACHE/ratelimits.json"
fi

pct=${pct%.*}; pct=${pct:-0}
used=$(( size * pct / 100000 ))   # k tokens
if   (( pct < 40 )); then c=32
elif (( pct < 70 )); then c=33
else c=31; fi
filled=$(( pct / 10 )); bar=""
for (( i = 0; i < 10; i++ )); do (( i < filled )) && bar+="█" || bar+="░"; done

branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null)
out="\e[35m${model}\e[0m · \e[${c}m${bar} ${used}k/$(( size / 1000 ))k\e[0m"
out+=" · \$$(printf '%.2f' "$cost")"
if [[ -n $five ]]; then
    f=${five%.*}
    (( f < 70 )) && fc=32 || { (( f < 90 )) && fc=33 || fc=31; }
    out+=" · \e[${fc}m5h ${f}%\e[0m"
fi
out+=" · \e[34m${dir/#$HOME/\~}\e[0m"
[[ -n $branch ]] && out+=" \e[36m${branch}\e[0m"
printf '%b' "$out"
