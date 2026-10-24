#!/usr/bin/env bash
# Atualização segura do sistema: comando `update` no terminal, ou central de controle → Tools.
#   1. mostra as notícias do Arch desde a última atualização (às vezes pedem um passo manual)
#   2. atualiza pacotes oficiais + AUR (yay)
#   3. avisa sobre .pacnew, firmware novo (fwupd), pacotes órfãos e se precisa reiniciar
STAMP=~/.cache/update-last
b() { printf '\n\e[1;35m==>\e[0m \e[1m%s\e[0m\n' "$*"; }

b "Notícias do Arch Linux"
since=$(cat "$STAMP" 2>/dev/null || echo 0)
curl -fsSL --max-time 10 https://archlinux.org/feeds/news/ 2>/dev/null | python3 -c '
import sys, xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
since = float(sys.argv[1])
try:
    items = ET.parse(sys.stdin).getroot().iter("item")
except ET.ParseError:
    print("    (não consegui ler as notícias agora)"); sys.exit()
shown = 0
for it in items:
    when = parsedate_to_datetime(it.findtext("pubDate"))
    if since and when.timestamp() <= since:
        break
    if not since and shown == 3:
        break
    title, link = it.findtext("title"), it.findtext("link")
    print(f"    \033[1;33m{when:%d/%m/%Y}\033[0m  {title}")
    print(f"               {link}")
    shown += 1
if shown == 0:
    print("    Nada novo desde a última atualização.")
' "$since"
echo
read -rp "Continuar com a atualização? [S/n] " ok
[[ ${ok,,} == n* ]] && exit 0

b "Pacotes (oficiais + AUR)"
yay -Syu || { echo "A atualização falhou; veja as mensagens acima."; read -rp "Enter para fechar"; exit 1; }
date +%s > "$STAMP"

b "Arquivos de configuração novos (.pacnew)"
pacnew=$(pacdiff -o 2>/dev/null)
if [ -n "$pacnew" ]; then
    echo "$pacnew" | sed 's/^/    /'
    echo "    Compare e junte com: sudo DIFFPROG='nvim -d' pacdiff"
else
    echo "    Nenhum."
fi

b "Firmware (fwupd)"
if command -v fwupdmgr >/dev/null; then
    fwupdmgr refresh >/dev/null 2>&1
    if fwupdmgr get-updates --no-unreported-check 2>/dev/null | grep -qiE "upgrade|update available|→"; then
        fwupdmgr get-updates --no-unreported-check 2>/dev/null | sed 's/^/    /'
        echo "    Para instalar: fwupdmgr update"
    else
        echo "    Tudo atualizado."
    fi
fi

b "Pacotes órfãos (instalados como dependência e não usados mais)"
orphans=$(pacman -Qdtq)
if [ -n "$orphans" ]; then
    echo "$orphans" | tr '\n' ' ' | fold -s -w 90 | sed 's/^/    /'; echo
    echo "    Para remover: sudo pacman -Rns \$(pacman -Qdtq)"
else
    echo "    Nenhum."
fi

# Kernel novo instalado: os módulos do kernel em uso somem até reiniciar
if [ ! -d "/usr/lib/modules/$(uname -r)" ]; then
    b "Kernel atualizado: reinicie quando puder (sudo reboot)"
fi
echo
read -rp "Pronto. Enter para fechar " _
