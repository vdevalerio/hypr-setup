#!/usr/bin/env bash
# Roda um programa só na GPU integrada (o contrário do prime-run): EGL, GLX e Vulkan sem a NVIDIA.
#   igpu.sh <programa> [args...]
# Usado no que fica aberto o tempo todo (wallpaper animado, notificações, polkit): se qualquer um
# deles abre a NVIDIA, ela não consegue desligar e gasta bateria. Sem GPU híbrida, só executa.

if [[ -e /dev/nvidiactl ]] && [[ -f /usr/share/glvnd/egl_vendor.d/50_mesa.json ]]; then
    export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
    export __GLX_VENDOR_LIBRARY_NAME=mesa
    export CUDA_VISIBLE_DEVICES=    # CUDA (ex.: decodificação de vídeo do mpv) não enxerga a NVIDIA
    icds=$(ls /usr/share/vulkan/icd.d/{radeon,intel}_icd*.json 2>/dev/null | paste -sd:)
    [[ -n $icds ]] && export VK_DRIVER_FILES=$icds
fi
exec "$@"
