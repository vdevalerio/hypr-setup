#!/usr/bin/env bash
# Runs a program on the integrated GPU only (the opposite of prime-run): EGL, GLX and Vulkan without NVIDIA.
#   igpu.sh <program> [args...]
# Used for things that stay open all the time (animated wallpaper, notifications, polkit): if any of
# them opens the NVIDIA GPU, it can't power off and drains the battery. Without a hybrid GPU, it just executes.

if [[ -e /dev/nvidiactl ]] && [[ -f /usr/share/glvnd/egl_vendor.d/50_mesa.json ]]; then
    export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
    export __GLX_VENDOR_LIBRARY_NAME=mesa
    export CUDA_VISIBLE_DEVICES=    # CUDA (e.g. mpv video decoding) can't see the NVIDIA GPU
    icds=$(ls /usr/share/vulkan/icd.d/{radeon,intel}_icd*.json 2>/dev/null | paste -sd:)
    [[ -n $icds ]] && export VK_DRIVER_FILES=$icds
fi
exec "$@"
