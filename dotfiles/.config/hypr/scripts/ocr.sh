#!/usr/bin/env bash
# Copia o texto de uma área da tela (OCR com tesseract). SUPER + CTRL + S.
#   ocr.sh [idiomas]   padrão: por+eng · outros: jpn, rus (ex.: ocr.sh jpn)
langs=${1:-por+eng}
geom=$(slurp -d -b 1e1e2e88 -c cba6f7ff -w 2) || exit 0
# Amplia 2x antes do OCR: texto de tela é pequeno e o tesseract erra menos com letras maiores
text=$(grim -g "$geom" - | magick - -resize 200% -colorspace Gray png:- | tesseract - - -l "$langs" 2>/dev/null |
       sed -e 's/[[:space:]]*$//' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
if [ -z "${text//[[:space:]]/}" ]; then
    notify-send -a ocr "No text found" "Try a larger area, or another language (control center → Tools)"
    exit 0
fi
printf '%s' "$text" | wl-copy
notify-send -a ocr "Text copied" "$(printf '%s' "$text" | head -c 200)"
