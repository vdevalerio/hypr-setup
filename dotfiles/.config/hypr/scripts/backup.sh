#!/usr/bin/env bash
# Backup dos seus arquivos: restic (criptografado, incremental) no Google Drive, via rclone.
#   backup.sh setup      primeira vez: autoriza o Google Drive e cria o repositório
#   backup.sh drive-client   usa a SUA credencial do Google (client ID): a compartilhada do rclone
#                            está sendo desativada e estoura o limite (erro "Quota exceeded")
#   backup.sh run        faz o backup agora (o timer diário roda sozinho: backup.timer)
#   backup.sh status     último backup, tamanho e quantas versões existem
#   backup.sh list       versões salvas (snapshots)
#   backup.sh restore <versão|latest> <pasta-destino>   recupera arquivos
#
# A senha do repositório fica em ~/.config/restic/password. SEM ELA NÃO DÁ PARA RECUPERAR NADA:
# guarde uma cópia no KeePassXC. Mantém 7 diários, 4 semanais e 6 mensais.
export RESTIC_REPOSITORY="rclone:gdrive:Backups/restic-$(uname -n)"   # uname: o comando hostname nem sempre vem instalado
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/password"
STATUS=~/.cache/backup-last

PATHS=(~/Documents ~/Projects ~/Desktop ~/Pictures ~/Music ~/.ssh ~/.gnupg ~/.local/share/keyrings
       ~/.config/keepassxc ~/hypr-setup)
EXCLUDES=(node_modules .venv venv __pycache__ .mypy_cache .ruff_cache .pytest_cache .ipynb_checkpoints
          .cache target dist build '*.iso' '*.tmp')

existing() { local p; for p in "${PATHS[@]}"; do [ -e "$p" ] && printf '%s\n' "$p"; done; }
ready() { [ -s "$RESTIC_PASSWORD_FILE" ] && rclone listremotes 2>/dev/null | grep -qx 'gdrive:'; }

drive_client() {
    cat <<'MSG'
Crie a sua credencial (uma vez, grátis) em https://console.cloud.google.com :
  1. Crie um projeto (ex.: "rclone backup").
  2. APIs e serviços → Biblioteca → "Google Drive API" → Ativar.
  3. Tela de consentimento OAuth (Google Auth Platform): tipo Externo, preencha nome e e-mail,
     e em Público-alvo clique em "Publicar app" (com o escopo drive.file não precisa de verificação;
     em modo "Teste" a autorização expira a cada 7 dias).
  4. Clientes → Criar cliente → tipo "App para computador" → copie o ID e a chave secreta.
MSG
    local id secret
    read -rp "Client ID: " id
    read -rp "Client secret: " secret
    [ -n "$id" ] && [ -n "$secret" ] || { echo "Cancelado."; exit 1; }
    rclone config update gdrive client_id "$id" client_secret "$secret" >/dev/null || exit 1
    echo "Autorize de novo no navegador com a credencial nova…"
    rclone config reconnect gdrive: || exit 1
    echo "Pronto. Teste com: backup.sh run"
}

setup() {
    if ! rclone listremotes 2>/dev/null | grep -qx 'gdrive:'; then
        echo "Abrindo o navegador para autorizar o Google Drive (o rclone só vê os arquivos que ele mesmo criar)…"
        rclone config create gdrive drive scope=drive.file || exit 1
    fi
    if [ ! -s "$RESTIC_PASSWORD_FILE" ]; then
        mkdir -p "$(dirname "$RESTIC_PASSWORD_FILE")"
        ( umask 077; head -c 32 /dev/urandom | base64 > "$RESTIC_PASSWORD_FILE" )
    fi
    restic cat config >/dev/null 2>&1 || restic init || exit 1
    systemctl --user enable --now backup.timer
    cat <<MSG

  Backup configurado: roda todo dia (e ao ligar, se perdeu o horário).
  ┌──────────────────────────────────────────────────────────────────────┐
  │  GUARDE A SENHA DO BACKUP no KeePassXC — sem ela não há recuperação: │
  │     cat ~/.config/restic/password                                    │
  └──────────────────────────────────────────────────────────────────────┘
  Primeiro backup agora: backup.sh run
MSG
}

run() {
    ready || { notify-send -a backup -u critical "Backup not configured" "Run: ~/.config/hypr/scripts/backup.sh setup"; exit 1; }
    local ex=() e
    for e in "${EXCLUDES[@]}"; do ex+=(--exclude "$e"); done
    mapfile -t paths < <(existing)
    if nice -n 10 restic backup --tag auto --one-file-system "${ex[@]}" "${paths[@]}" &&
       restic forget --tag auto --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune; then
        echo "ok $(date '+%Y-%m-%d %H:%M')" > "$STATUS"
        [ "${1:-}" = --quiet ] || notify-send -a backup "Backup done" "Saved to Google Drive"
    else
        echo "fail $(date '+%Y-%m-%d %H:%M')" > "$STATUS"
        notify-send -a backup -u critical "Backup failed" "See: journalctl --user -u backup"
        exit 1
    fi
}

status() {
    ready || { echo "não configurado (backup.sh setup)"; return; }
    echo "Último: $(cat "$STATUS" 2>/dev/null || echo nunca)"
    restic snapshots --compact --latest 1 2>/dev/null | tail -n +1
    restic stats --mode raw-data 2>/dev/null | grep -E "Total Size|Snapshots"
}

case "${1:-}" in
    setup)   setup ;;
    drive-client) drive_client ;;
    run)     run "${2:-}" ;;
    status)  status ;;
    list)    restic snapshots ;;
    restore) restic restore "${2:?versão (ou latest)}" --target "${3:?pasta de destino}" ;;
    *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
