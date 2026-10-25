#!/usr/bin/env bash
# Gera os temas do GRUB e do Plymouth (splash do boot) com as cores do tema atual
# (~/.config/hypr/sddm-colors.conf, escrito pelo theme.py) e o fundo da tela de login.
#   make-themes.sh <pasta de saída>     → <saída>/grub e <saída>/plymouth
# Quem instala no sistema é o `install.sh boot` (rode de novo depois de trocar de tema).
set -euo pipefail
OUT=${1:?uso: make-themes.sh <pasta de saída>}
COLORS=$HOME/.config/hypr/sddm-colors.conf
BG=/usr/share/sddm/themes/hypr-setup/dynamic/background.jpg
FONT=/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf
FONT_BOLD=/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf

cor() { local v; v=$(sed -n "s/^$1=//p" "$COLORS" 2>/dev/null); echo "${v:-$2}"; }
accent=$(cor accent "#cba6f7"); accent2=$(cor accent2 "#89b4fa"); text=$(cor text "#cdd6f4")
subtext=$(cor subtext "#a6adc8"); base=$(cor base "#1e1e2e"); crust=$(cor crust "#11111b")

G=$OUT/grub; P=$OUT/plymouth
rm -rf "$G" "$P"; mkdir -p "$G" "$P"

# ── Fundo comum: o mesmo da tela de login (já desfocado), um pouco mais escuro ──
if [[ -f $BG ]]; then
    magick "$BG" -resize 1920x1080^ -gravity center -extent 1920x1080 -fill "$crust" -colorize 30% "$G/background.png"
else
    magick -size 1920x1080 xc:"$crust" "$G/background.png"
fi

# ── GRUB ─────────────────────────────────────────────────────────────────────
# -n fixa o nome que o theme.txt usa (sem depender de como o grub-mkfont batizaria a fonte)
# -r: só os caracteres usados (latim, setas, pontos): fonte de ~2 MB vira poucos KB
RANGE="0x20-0x7E,0xA0-0x17F,0x2022-0x2022,0x2190-0x2193"
grub-mkfont -r "$RANGE" -s 22 -n "Hypr Regular 22" -o "$G/regular-22.pf2" "$FONT" 2>/dev/null
grub-mkfont -r "$RANGE" -s 16 -n "Hypr Regular 16" -o "$G/regular-16.pf2" "$FONT" 2>/dev/null
grub-mkfont -r "$RANGE" -s 30 -n "Hypr Bold 30"    -o "$G/bold-30.pf2"    "$FONT_BOLD" 2>/dev/null

# Item selecionado: pílula em gradiente fatiada em 9 partes (o GRUB estica as bordas e o centro)
pill=$(mktemp --suffix=.png)
magick \( -size 240x48 -define gradient:angle=90 "gradient:$accent-$accent2" \) \
       \( -size 240x48 xc:none -fill white -draw "roundrectangle 0,0 239,47 14,14" \) \
       -compose CopyOpacity -composite "$pill"
for p in "nw 14x14+0+0" "n 212x14+14+0" "ne 14x14+226+0" "w 14x20+0+14" "c 212x20+14+14" "e 14x20+226+14" \
         "sw 14x14+0+34" "s 212x14+14+34" "se 14x14+226+34"; do
    magick "$pill" -crop "${p#* }" +repage "$G/select_${p%% *}.png"
done
rm -f "$pill"

cat > "$G/theme.txt" <<EOF
# Tema do GRUB do hypr-setup (gerado por system/boot/make-themes.sh — não edite)
title-text: ""
desktop-image: "background.png"
desktop-image-scale-method: "crop"
desktop-color: "$crust"
terminal-font: "Hypr Regular 16"
terminal-left: "10%"
terminal-top: "10%"
terminal-width: "80%"
terminal-height: "80%"

+ label {
    top = 24%
    left = 0
    width = 100%
    align = "center"
    text = "Arch Linux"
    font = "Hypr Bold 30"
    color = "$text"
}

+ boot_menu {
    left = 30%
    width = 40%
    top = 34%
    height = 40%
    item_font = "Hypr Regular 22"
    item_color = "$subtext"
    selected_item_font = "Hypr Regular 22"
    selected_item_color = "$crust"
    selected_item_pixmap_style = "select_*.png"
    item_height = 48
    item_padding = 18
    item_spacing = 10
    icon_width = 0
    icon_height = 0
    item_icon_space = 0
    scrollbar = false
}

+ label {
    id = "__timeout__"
    top = 80%
    left = 0
    width = 100%
    align = "center"
    font = "Hypr Regular 16"
    color = "$subtext"
    text = "Booting in %d s"
}

+ label {
    top = 88%
    left = 0
    width = 100%
    align = "center"
    font = "Hypr Regular 16"
    color = "$subtext"
    text = "↑ ↓ choose  ·  Enter boot  ·  E edit  ·  C console"
}
EOF

# ── Plymouth ─────────────────────────────────────────────────────────────────
cp "$G/background.png" "$P/background.png"
# Logo do Arch em gradiente (glifo da Nerd Font)
mask=$(mktemp --suffix=.png)
magick -background none -fill white -font "$FONT" -pointsize 150 label:$'' -trim +repage "$mask"
size=$(magick identify -format "%wx%h" "$mask")
magick \( -size "$size" -define gradient:angle=135 "gradient:$accent-$accent2" \) "$mask" \
       -compose CopyOpacity -composite "$P/logo.png"
rm -f "$mask"
# Barra de progresso: trilho discreto + preenchimento em gradiente
magick -size 220x4 xc:none -fill "${text}33" -draw "roundrectangle 0,0 219,3 2,2" "$P/track.png"
magick \( -size 220x4 -define gradient:angle=90 "gradient:$accent-$accent2" \) \
       \( -size 220x4 xc:none -fill white -draw "roundrectangle 0,0 219,3 2,2" \) \
       -compose CopyOpacity -composite "$P/bar.png"

rgb() { printf '%s' "${1#\#}" | awk '{ printf "%.3f, %.3f, %.3f", strtonum("0x" substr($0,1,2))/255, strtonum("0x" substr($0,3,2))/255, strtonum("0x" substr($0,5,2))/255 }'; }

cat > "$P/hypr-setup.plymouth" <<EOF
[Plymouth Theme]
Name=hypr-setup
Description=Splash do hypr-setup: logo e progresso com as cores do tema
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/hypr-setup
ScriptFile=/usr/share/plymouth/themes/hypr-setup/hypr-setup.script
EOF

cat > "$P/hypr-setup.script" <<EOF
# Splash do hypr-setup (gerado por system/boot/make-themes.sh — não edite)
Window.SetBackgroundTopColor($(rgb "$crust"));
Window.SetBackgroundBottomColor($(rgb "$crust"));

cx = Window.GetX() + Window.GetWidth() / 2;
cy = Window.GetY() + Window.GetHeight() / 2;

bg.image = Image("background.png").Scale(Window.GetWidth(), Window.GetHeight());
bg.sprite = Sprite(bg.image);
bg.sprite.SetPosition(Window.GetX(), Window.GetY(), -10);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetPosition(cx - logo.image.GetWidth() / 2, cy - logo.image.GetHeight() / 2 - 40, 1);
logo.sprite.SetOpacity(0);

track.image = Image("track.png");
track.sprite = Sprite(track.image);
track.y = cy + logo.image.GetHeight() / 2 + 20;
track.sprite.SetPosition(cx - track.image.GetWidth() / 2, track.y, 1);

bar.original = Image("bar.png");
bar.sprite = Sprite();
bar.sprite.SetPosition(cx - bar.original.GetWidth() / 2, track.y, 2);

fun progress_cb(duration, progress) {
    w = Math.Int(bar.original.GetWidth() * progress);
    if (w < 2) w = 2;
    bar.sprite.SetImage(bar.original.Scale(w, bar.original.GetHeight()));
}
Plymouth.SetBootProgressFunction(progress_cb);

# Logo aparece suavemente
frame = 0;
fun refresh_cb() {
    frame++;
    opacity = frame / 40;
    if (opacity > 1) opacity = 1;
    logo.sprite.SetOpacity(opacity);
}
Plymouth.SetRefreshFunction(refresh_cb);

# Senha (só aparece se o disco for criptografado): pontos abaixo da barra
prompt.sprite = Sprite();
fun display_password_cb(text, bullets) {
    s = text + "  ";
    for (i = 0; i < bullets; i++) s += "•";
    prompt.sprite.SetImage(Image.Text(s, $(rgb "$text"), 1, "Sans 14"));
    prompt.sprite.SetPosition(cx - prompt.sprite.GetImage().GetWidth() / 2, track.y + 40, 3);
    prompt.sprite.SetOpacity(1);
}
fun display_normal_cb() { prompt.sprite.SetOpacity(0); }
Plymouth.SetDisplayPasswordFunction(display_password_cb);
Plymouth.SetDisplayNormalFunction(display_normal_cb);

# Mensagens do sistema (ex.: verificação do disco)
msg.sprite = Sprite();
fun message_cb(text) {
    msg.sprite.SetImage(Image.Text(text, $(rgb "$subtext"), 1, "Sans 12"));
    msg.sprite.SetPosition(cx - msg.sprite.GetImage().GetWidth() / 2, Window.GetY() + Window.GetHeight() - 60, 3);
}
Plymouth.SetMessageFunction(message_cb);
EOF

echo "Temas gerados em $OUT (grub/, plymouth/)"
