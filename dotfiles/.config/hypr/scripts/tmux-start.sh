#!/usr/bin/env bash
# Shell for kitty (shell option in kitty.conf): every terminal opens inside tmux.
# Attaches to a saved session that nobody is using (tmux-continuum restores them when the server
# starts); if all are in use, or there are none, opens a new one. Falls back to plain zsh.
command -v tmux >/dev/null && [[ -z ${TMUX:-} ]] || exec zsh "$@"

tmux start-server \; has-session 2>/dev/null || tmux new-session -d   # the server restores the saved sessions
# right after the server starts the restore is still running: wait for it
start=$(tmux display-message -p '#{start_time}')
while (( $(date +%s) - start < 4 )); do sleep 0.3; done

free=$(tmux list-sessions -F '#{session_attached} #{session_name}' | awk '$1 == 0 { print $2; exit }')
if [[ -n $free ]]; then exec tmux attach -t "=$free"; else exec tmux new-session; fi
