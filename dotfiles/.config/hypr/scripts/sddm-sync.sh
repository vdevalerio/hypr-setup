#!/usr/bin/env bash
# Deixa a tela de login (SDDM, tema hypr-setup) igual à tela de bloqueio: fundo do wallpaper
# desfocado, cores do wallpaper e foto de perfil. O SDDM não lê a home, então os arquivos vão
# para uma pasta do tema que pertence ao usuário (criada pelo install.sh).
# Chamado sozinho pelo wallpaper.sh e pelo avatar.sh; rode à mão com: sddm-sync.sh [--force]

DEST=${SDDM_DYNAMIC:-/usr/share/sddm/themes/hypr-setup/dynamic}   # SDDM_DYNAMIC: só para testes
LOCKBG=~/.cache/wallpaper/lock.png
[ -d "$DEST" ] && [ -w "$DEST" ] || exit 0   # tema não instalado: nada a fazer

newer() { [ "${FORCE:-}" = 1 ] || [ ! -e "$2" ] || [ "$1" -nt "$2" ]; }
[ "${1:-}" = --force ] && FORCE=1

# Fundo parado: mesmo quadro da tela de bloqueio, já desfocado e escurecido (o greeter não
# aplica efeitos). Aparece enquanto o vídeo carrega, e sozinho quando o wallpaper é imagem.
if [ -s "$LOCKBG" ] && newer "$LOCKBG" "$DEST/background.jpg"; then
    magick "$LOCKBG" -resize '1920x1080^' -gravity center -extent 1920x1080 \
        -blur 0x18 -modulate 55,125 -quality 92 "$DEST/background.tmp.jpg" &&
        mv -f "$DEST/background.tmp.jpg" "$DEST/background.jpg"
fi

# Fundo animado: wallpaper em vídeo ou GIF vira um vídeo já desfocado e escurecido, pequeno
# (960×540, até 60 s; o blur esconde a resolução). Refeito só quando o wallpaper muda.
WALL=$(cat ~/.cache/wallpaper/current 2>/dev/null)
case "$(file -b -L --mime-type "$WALL" 2>/dev/null)" in
    video/*|image/gif)
        if [ "$(cat "$DEST/background.src" 2>/dev/null)" != "$WALL" ] || [ ! -s "$DEST/background.mp4" ] ||
           [ "${FORCE:-}" = 1 ]; then
            nice -n 15 ffmpeg -nostdin -loglevel error -y -t 60 -i "$WALL" -an \
                -vf "fps=30,scale=960:540:force_original_aspect_ratio=increase,crop=960:540,gblur=sigma=10,lutrgb=r=val*0.55:g=val*0.55:b=val*0.55,eq=saturation=1.25,format=yuv420p" \
                -c:v libx264 -preset veryfast -crf 20 -movflags +faststart "$DEST/background.tmp.mp4" &&
                mv -f "$DEST/background.tmp.mp4" "$DEST/background.mp4" &&
                echo "$WALL" > "$DEST/background.src"
        fi ;;
    *) rm -f "$DEST/background.mp4" "$DEST/background.src" ;;
esac

# Cores (geradas pelo theme.py junto com as do resto do sistema)
if [ -s ~/.config/hypr/sddm-colors.conf ] && newer ~/.config/hypr/sddm-colors.conf "$DEST/theme.conf.user"; then
    cp -f ~/.config/hypr/sddm-colors.conf "$DEST/theme.conf.user"
fi

# Foto de perfil já recortada em círculo (sem foto: o tema mostra o ícone)
if [ -s ~/.face ]; then
    if newer ~/.face "$DEST/face.png"; then
        magick ~/.face -resize 256x256^ -gravity center -extent 256x256 \
            \( +clone -alpha transparent -fill white -draw 'circle 128,128 128,1' \) \
            -compose copy_opacity -composite "$DEST/face.tmp.png" &&
            mv -f "$DEST/face.tmp.png" "$DEST/face.png"
    fi
else
    rm -f "$DEST/face.png"
fi
chmod a+r "$DEST"/* 2>/dev/null
exit 0
