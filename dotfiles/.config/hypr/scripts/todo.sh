#!/usr/bin/env bash
# Daily to-do list in the todo.txt format (one task per line, "x DATE text" when done).
#   todo.sh                 list the pending tasks (numbered)
#   todo.sh add <text>      add a task
#   todo.sh done <n>        finish the task number n (as listed)
#   todo.sh undo <n>        reopen the n-th finished task (see `list -a`)
#   todo.sh rm <n>          delete the task number n
#   todo.sh list [-a]       pending tasks (-a: also the finished ones)
#   todo.sh clear           delete the finished tasks
#   todo.sh edit            open the file in $EDITOR
#   todo.sh status          JSON for Waybar
#   todo.sh menu            Rofi: pick a task to finish/reopen it, type text to add one (Esc closes)
# The `todo` command (~/.local/bin/todo) calls this script. Bar refresh: signal 13.
FILE=~/.local/share/todo/todo.txt
ICON=$'\U000F0279'                  # nf-md-format_list_checks
mkdir -p "${FILE%/*}"; touch "$FILE"

refresh_bar() { pkill -RTMIN+13 -x waybar; }
pending() { grep -v '^x ' "$FILE" | sed '/^[[:space:]]*$/d'; }
finished() { grep '^x ' "$FILE"; }
# nth <pending|finished> <n>: prints the n-th task line (empty if it does not exist)
nth() { "$1" | sed -n "${2}p"; }
# replace_line <old> <new>: rewrites the first line equal to <old> (empty <new> deletes it)
replace_line() {
    local old=$1 new=$2 tmp done=0 line
    tmp=$(mktemp)
    while IFS= read -r line || [[ -n $line ]]; do
        if (( ! done )) && [[ $line == "$old" ]]; then
            done=1; [[ -n $new ]] && printf '%s\n' "$new"
        else printf '%s\n' "$line"; fi
    done < "$FILE" > "$tmp"
    mv "$tmp" "$FILE"
}
add() { printf '%s\n' "$*" >> "$FILE"; }
finish() { replace_line "$1" "x $(date +%F) $1"; }
reopen() { replace_line "$1" "$(sed -E 's/^x [0-9-]+ //' <<<"$1")"; }
show() {
    local n=0 line
    while IFS= read -r line; do printf '%2d  %s\n' $((++n)) "$line"; done < <(pending)
    (( n )) || echo "Nothing pending."
    if [[ ${1:-} == -a ]]; then
        n=0; echo; echo "Finished:"
        while IFS= read -r line; do printf '%2d  %s\n' $((++n)) "${line#x }"; done < <(finished)
    fi
}
need_n() { [[ ${2:-} =~ ^[0-9]+$ ]] || { echo "usage: todo $1 <number>" >&2; exit 1; }; }

case "${1:-list}" in
add)
    shift; [[ -n $* ]] || { echo "usage: todo add <text>" >&2; exit 1; }
    add "$*"; refresh_bar; show ;;
done|d)
    need_n done "${2:-}"; t=$(nth pending "$2"); [[ -n $t ]] || { echo "No task $2." >&2; exit 1; }
    finish "$t"; refresh_bar; show ;;
undo)
    need_n undo "${2:-}"; t=$(nth finished "$2"); [[ -n $t ]] || { echo "No finished task $2." >&2; exit 1; }
    reopen "$t"; refresh_bar; show ;;
rm)
    need_n rm "${2:-}"; t=$(nth pending "$2"); [[ -n $t ]] || { echo "No task $2." >&2; exit 1; }
    replace_line "$t" ""; refresh_bar; show ;;
list|ls) show "${2:-}" ;;
clear)
    grep -v '^x ' "$FILE" > "$FILE.tmp"; mv "$FILE.tmp" "$FILE"; refresh_bar; show ;;
edit) "${EDITOR:-nvim}" "$FILE"; refresh_bar ;;
status)
    n=$(pending | grep -c .); f=$(finished | grep -c .)
    if (( n == 0 )); then
        jq -cn --arg t "$ICON" --arg tt "Nothing pending ($f done)"$'\n\nClick: open the list' '{text: $t, tooltip: $tt, class: "empty"}'
    else
        tip=$(pending | head -n 12 | sed 's/^/☐ /'; (( n > 12 )) && echo "… and $((n - 12)) more")
        jq -cn --arg t "$ICON $n" --arg tt "$n pending ($f done)"$'\n\n'"$tip"$'\n\nClick: open the list' '{text: $t, tooltip: $tt, class: "pending"}'
    fi ;;
menu)
    while :; do
        items=$({ pending | sed 's/^/☐  /'; finished | sed -E 's/^x [0-9-]+ /☑  /'; })
        sel=$(printf '%s\n' "$items" | sed '/^$/d' | rofi -dmenu -i -p "To-do" -mesg "Pick a task to finish/reopen it · type text and Enter to add one") || break
        [[ -n $sel ]] || break
        case $sel in
        "☐  "*) t=${sel#☐  }; finish "$t" ;;
        "☑  "*) t=${sel#☑  }; l=$(finished | grep -m1 -F -- " $t"); [[ -n $l ]] && reopen "$l" ;;
        *) add "$sel" ;;
        esac
        refresh_bar
    done ;;
*)  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
