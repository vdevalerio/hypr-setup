#!/usr/bin/env bash
# Backup of your files: restic (encrypted, incremental) to Google Drive, via rclone.
#   backup.sh setup      first time: authorizes Google Drive and creates the repository
#   backup.sh drive-client   uses YOUR own Google credential (client ID): rclone's shared one
#                            is being phased out and hits the limit ("Quota exceeded" error)
#   backup.sh run        runs a backup now (the daily timer runs on its own: backup.timer)
#   backup.sh status     last backup, size and how many versions exist
#   backup.sh list       saved versions (snapshots)
#   backup.sh restore <version|latest> <target-dir>   recovers files
#
# The repository password is in ~/.config/restic/password. WITHOUT IT NOTHING CAN BE RECOVERED:
# keep a copy in KeePassXC. Keeps 7 daily, 4 weekly and 6 monthly.
export RESTIC_REPOSITORY="rclone:gdrive:Backups/restic-$(uname -n)" # uname: the hostname command isn't always installed
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/password"
STATUS=~/.cache/backup-last

PATHS=(~/Projects/Growth ~/.ssh ~/.gnupg ~/.local/share/keyrings
  ~/.config/keepassxc ~/Projects/Personal/hypr-setup)
EXCLUDES=(node_modules .venv venv __pycache__ .mypy_cache .ruff_cache .pytest_cache .ipynb_checkpoints
  .cache target dist build '*.iso' '*.tmp')

existing() {
  local p
  for p in "${PATHS[@]}"; do [ -e "$p" ] && printf '%s\n' "$p"; done
}
ready() { [ -s "$RESTIC_PASSWORD_FILE" ] && rclone listremotes 2>/dev/null | grep -qx 'gdrive:'; }

drive_client() {
  cat <<'MSG'
Create your own credential (once, free) at https://console.cloud.google.com :
  1. Create a project (e.g. "rclone backup").
  2. APIs & Services → Library → "Google Drive API" → Enable.
  3. OAuth consent screen (Google Auth Platform): type External, fill in name and email,
     and under Audience click "Publish app" (with the drive.file scope no verification is needed;
     in "Testing" mode the authorization expires every 7 days).
  4. Clients → Create client → type "Desktop app" → copy the ID and the client secret.
MSG
  local id secret
  read -rp "Client ID: " id
  read -rp "Client secret: " secret
  [ -n "$id" ] && [ -n "$secret" ] || {
    echo "Cancelled."
    exit 1
  }
  rclone config update gdrive client_id "$id" client_secret "$secret" >/dev/null || exit 1
  echo "Authorize again in the browser with the new credential…"
  rclone config reconnect gdrive: || exit 1
  echo "Done. Test with: backup.sh run"
}

setup() {
  if ! rclone listremotes 2>/dev/null | grep -qx 'gdrive:'; then
    echo "Opening the browser to authorize Google Drive (rclone only sees the files it creates itself)…"
    rclone config create gdrive drive scope=drive.file || exit 1
  fi
  if [ ! -s "$RESTIC_PASSWORD_FILE" ]; then
    mkdir -p "$(dirname "$RESTIC_PASSWORD_FILE")"
    (
      umask 077
      head -c 32 /dev/urandom | base64 >"$RESTIC_PASSWORD_FILE"
    )
  fi
  restic cat config >/dev/null 2>&1 || restic init || exit 1
  systemctl --user enable --now backup.timer
  cat <<MSG

  Backup configured: runs every day (and at boot, if it missed its time).
  ┌──────────────────────────────────────────────────────────────────────┐
  │  SAVE THE BACKUP PASSWORD in KeePassXC — without it there is no      │
  │  recovery:                                                           │
  │     cat ~/.config/restic/password                                    │
  └──────────────────────────────────────────────────────────────────────┘
  First backup now: backup.sh run
MSG
}

run() {
  ready || {
    notify-send -a backup -u critical "Backup not configured" "Run: ~/.config/hypr/scripts/backup.sh setup"
    exit 1
  }
  local ex=() e
  for e in "${EXCLUDES[@]}"; do ex+=(--exclude "$e"); done
  mapfile -t paths < <(existing)
  if nice -n 10 restic backup --tag auto --one-file-system "${ex[@]}" "${paths[@]}" &&
    restic forget --tag auto --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune; then
    echo "ok $(date '+%Y-%m-%d %H:%M')" >"$STATUS"
    [ "${1:-}" = --quiet ] || notify-send -a backup "Backup done" "Saved to Google Drive"
  else
    echo "fail $(date '+%Y-%m-%d %H:%M')" >"$STATUS"
    notify-send -a backup -u critical "Backup failed" "See: journalctl --user -u backup"
    exit 1
  fi
}

status() {
  ready || {
    echo "not configured (backup.sh setup)"
    return
  }
  echo "Last: $(cat "$STATUS" 2>/dev/null || echo never)"
  restic snapshots --compact --latest 1 2>/dev/null | tail -n +1
  restic stats --mode raw-data 2>/dev/null | grep -E "Total Size|Snapshots"
}

case "${1:-}" in
setup) setup ;;
drive-client) drive_client ;;
run) run "${2:-}" ;;
status) status ;;
list) restic snapshots ;;
restore) restic restore "${2:?version (or latest)}" --target "${3:?target directory}" ;;
*)
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
  ;;
esac
