#!/usr/bin/env bash
# Safe system update: the `update` command in the terminal, or control center → Tools.
#   1. shows the Arch news since the last update (sometimes they require a manual step)
#   2. updates official packages + AUR (yay)
#   3. warns about .pacnew files, new firmware (fwupd), orphaned packages and whether a reboot is needed
STAMP=~/.cache/update-last
b() { printf '\n\e[1;35m==>\e[0m \e[1m%s\e[0m\n' "$*"; }

b "Arch Linux news"
since=$(cat "$STAMP" 2>/dev/null || echo 0)
curl -fsSL --max-time 10 https://archlinux.org/feeds/news/ 2>/dev/null | python3 -c '
import sys, xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
since = float(sys.argv[1])
try:
    items = ET.parse(sys.stdin).getroot().iter("item")
except ET.ParseError:
    print("    (could not read the news right now)"); sys.exit()
shown = 0
for it in items:
    when = parsedate_to_datetime(it.findtext("pubDate"))
    if since and when.timestamp() <= since:
        break
    if not since and shown == 3:
        break
    title, link = it.findtext("title"), it.findtext("link")
    print(f"    \033[1;33m{when:%Y-%m-%d}\033[0m  {title}")
    print(f"               {link}")
    shown += 1
if shown == 0:
    print("    Nothing new since the last update.")
' "$since"
echo
read -rp "Continue with the update? [Y/n] " ok
[[ ${ok,,} == n* ]] && exit 0

b "Packages (official + AUR)"
yay -Syu || { echo "The update failed; see the messages above."; read -rp "Enter to close"; exit 1; }
date +%s > "$STAMP"

b "New configuration files (.pacnew)"
pacnew=$(pacdiff -o 2>/dev/null)
if [ -n "$pacnew" ]; then
    echo "$pacnew" | sed 's/^/    /'
    echo "    Compare and merge with: sudo DIFFPROG='nvim -d' pacdiff"
else
    echo "    None."
fi

b "Firmware (fwupd)"
if command -v fwupdmgr >/dev/null; then
    fwupdmgr refresh >/dev/null 2>&1
    if fwupdmgr get-updates --no-unreported-check 2>/dev/null | grep -qiE "upgrade|update available|→"; then
        fwupdmgr get-updates --no-unreported-check 2>/dev/null | sed 's/^/    /'
        echo "    To install: fwupdmgr update"
    else
        echo "    Everything is up to date."
    fi
fi

b "Orphaned packages (installed as dependencies and no longer used)"
orphans=$(pacman -Qdtq)
if [ -n "$orphans" ]; then
    echo "$orphans" | tr '\n' ' ' | fold -s -w 90 | sed 's/^/    /'; echo
    echo "    To remove: sudo pacman -Rns \$(pacman -Qdtq)"
else
    echo "    None."
fi

# New kernel installed: the running kernel's modules disappear until reboot
if [ ! -d "/usr/lib/modules/$(uname -r)" ]; then
    b "Kernel updated: reboot when you can (sudo reboot)"
fi
echo
read -rp "Done. Press Enter to close " _
