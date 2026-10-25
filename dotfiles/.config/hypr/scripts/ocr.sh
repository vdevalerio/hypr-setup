#!/usr/bin/env bash
# Copies the text from a screen area (OCR with tesseract). SUPER + CTRL + S.
#   ocr.sh [languages]   default: por+eng · others: jpn, rus (e.g. ocr.sh jpn)
langs=${1:-por+eng}
geom=$(slurp -d -b 1e1e2e88 -c cba6f7ff -w 2) || exit 0
# Upscale 2x before OCR: screen text is small and tesseract makes fewer mistakes with larger letters
text=$(grim -g "$geom" - | magick - -resize 200% -colorspace Gray png:- | tesseract - - -l "$langs" 2>/dev/null |
       sed -e 's/[[:space:]]*$//' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
if [ -z "${text//[[:space:]]/}" ]; then
    notify-send -a ocr "No text found" "Try a larger area, or another language (control center → Tools)"
    exit 0
fi
printf '%s' "$text" | wl-copy
notify-send -a ocr "Text copied" "$(printf '%s' "$text" | head -c 200)"
