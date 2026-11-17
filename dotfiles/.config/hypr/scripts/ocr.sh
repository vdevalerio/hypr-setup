#!/usr/bin/env bash
# Copies the text from a screen area (OCR with tesseract). SUPER + CTRL + S.
#   ocr.sh                 languages = the keyboard languages in ~/.config/fcitx5/profile (+ English), so adding
#                          a keyboard language (e.g. German) also adds it to the OCR; missing models are
#                          downloaded by themselves into ~/.local/share/tessdata
#   ocr.sh <languages>     explicit (tesseract codes, e.g. jpn or rus+eng)
#   ocr.sh langs           prints the languages that would be used
PROFILE=~/.config/fcitx5/profile
DATA=${XDG_DATA_HOME:-$HOME/.local/share}/tessdata
MODELS=https://github.com/tesseract-ocr/tessdata_best/raw/main

# fcitx5 input method -> tesseract language
tess() {
    case $1 in
        keyboard-br* | keyboard-pt*) echo por ;;
        keyboard-us* | keyboard-gb* | keyboard-ca*) echo eng ;;
        keyboard-ru*) echo rus ;;
        keyboard-ua*) echo ukr ;;
        keyboard-by*) echo bel ;;
        keyboard-bg*) echo bul ;;
        keyboard-rs*) echo srp ;;
        keyboard-de* | keyboard-at* | keyboard-ch*) echo deu ;;
        keyboard-fr*) echo fra ;;
        keyboard-es* | keyboard-latam*) echo spa ;;
        keyboard-it*) echo ita ;;
        keyboard-nl*) echo nld ;;
        keyboard-pl*) echo pol ;;
        keyboard-cz*) echo ces ;;
        keyboard-sk*) echo slk ;;
        keyboard-hu*) echo hun ;;
        keyboard-ro*) echo ron ;;
        keyboard-se*) echo swe ;;
        keyboard-no*) echo nor ;;
        keyboard-dk*) echo dan ;;
        keyboard-fi*) echo fin ;;
        keyboard-tr*) echo tur ;;
        keyboard-gr*) echo ell ;;
        keyboard-il*) echo heb ;;
        keyboard-ara* | keyboard-ar*) echo ara ;;
        keyboard-ir*) echo fas ;;
        keyboard-th*) echo tha ;;
        keyboard-kr* | hangul*) echo kor ;;
        mozc | anthy* | kkc | skk) echo jpn ;;
        pinyin* | shuangpin* | fcitx5-chinese* | table:wubi*) echo chi_sim ;;
        chewing | zhuyin*) echo chi_tra ;;
        *) ;;
    esac
}

auto_langs() {
    local im l out=(eng)
    while read -r im; do
        l=$(tess "$im")
        [[ -n $l && " ${out[*]} " != *" $l "* ]] && out+=("$l")
    done < <(awk -F= '/^\[Groups\/0\/Items\/[0-9]+\]/ { item = 1; next } /^\[/ { item = 0 }
        item && $1 == "Name" { print $2 }' "$PROFILE" 2>/dev/null)
    local IFS=+
    echo "${out[*]}"
}

# One tessdata dir: links to the system models plus the ones downloaded here (tesseract takes a single dir)
prepare() {
    local l miss=() missing=()
    mkdir -p "$DATA"
    for f in /usr/share/tessdata/*.traineddata; do [[ -e $f ]] && ln -sf "$f" "$DATA/${f##*/}"; done
    IFS=+ read -ra miss <<<"$1"
    for l in "${miss[@]}"; do
        [[ -s $DATA/$l.traineddata ]] && continue
        notify-send -a ocr "OCR: downloading the '$l' model" "Only the first time"
        if curl -fsSL -o "$DATA/$l.traineddata.part" "$MODELS/$l.traineddata"; then mv "$DATA/$l.traineddata.part" "$DATA/$l.traineddata"
        else rm -f "$DATA/$l.traineddata.part"; missing+=("$l"); fi
    done
    local ok=()
    for l in "${miss[@]}"; do [[ -s $DATA/$l.traineddata ]] && ok+=("$l"); done
    if ((${#missing[@]})); then notify-send -a ocr -u critical "OCR: model not available" "${missing[*]} (check the connection or the language code)"; fi
    local IFS=+
    echo "${ok[*]}"
}

if [[ ${1:-} == langs ]]; then auto_langs; exit 0; fi
langs=${1:-$(auto_langs)}
langs=$(prepare "$langs")
[[ -n $langs ]] || exit 1
geom=$(slurp -d -b 1e1e2e88 -c cba6f7ff -w 2) || exit 0
# Upscale 2x before OCR: screen text is small and tesseract makes fewer mistakes with larger letters
text=$(grim -g "$geom" - | magick - -resize 200% -colorspace Gray png:- |
    tesseract - - --tessdata-dir "$DATA" -l "$langs" 2>/dev/null |
    sed -e 's/[[:space:]]*$//' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
if [ -z "${text//[[:space:]]/}" ]; then
    notify-send -a ocr "No text found" "Try a larger area, or force a language: ocr.sh rus ($langs was used)"
    exit 0
fi
printf '%s' "$text" | wl-copy
notify-send -a ocr "Text copied ($langs)" "$(printf '%s' "$text" | head -c 200)"
