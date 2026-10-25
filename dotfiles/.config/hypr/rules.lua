--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- Find a window's "class" with: hyprctl clients

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fixes dragging issues on XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Utilities open floating and centered
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|blueman-manager|nm-connection-editor|org.gnome.FileRoller|file-roller|nwg-look|qt6ct|btop-float|nmtui-float|xdg-desktop-portal-gtk|hyprland-share-picker|org.kde.polkit-kde-authentication-agent-1|hyprpolkitagent)$" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.5", "monitor_h*0.6" },
})

-- btop (the bar's monitoring island) needs more room than the other utilities
hl.window_rule({
    name  = "btop-size",
    match = { class = "^btop-float$" },
    size  = { "monitor_w*0.75", "monitor_h*0.8" },
})

hl.window_rule({
    name  = "float-dialogs",
    match = { title = "^(Abrir arquivo|Abrir pasta|Salvar como|Open File|Open Folder|Save As|Save File|File Upload|Choose Files|Library)(.*)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-viewers",
    match = { class = "^(imv|mpv)$" },
    float  = true,
    center = true,
})

-- matplotlib figures (plt.show()) open floating
hl.window_rule({
    name  = "matplotlib-figures",
    match = { title = "^(Figure \\d+)$" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.6", "monitor_h*0.65" },
})

hl.window_rule({
    name  = "satty-editor",
    match = { class = "^(com.gabm.satty|satty)$" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.8", "monitor_h*0.8" },
})

-- Browser picture-in-picture: pinned in the corner, on all workspaces
hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture|Picture in picture|Imagem em imagem)$" },
    float = true,
    pin   = true,
    size  = { "monitor_w*0.28", "monitor_h*0.28" },
    move  = { "monitor_w*0.71", "monitor_h*0.69" },
    keep_aspect_ratio = true,
})

-- Keeps the screen from turning off during fullscreen videos
hl.window_rule({
    name  = "idle-inhibit-fullscreen",
    match = { class = ".*" },
    idle_inhibit = "fullscreen",
})

-- Terminal: transparency is handled by kitty (background_opacity); this only ensures
-- full window opacity so the text doesn't look faded when unfocused
hl.window_rule({
    name  = "kitty-opaque-text",
    match = { class = "^(kitty)$" },
    opacity = "1.0 override 1.0 override",
})


---------------------
---- LAYER RULES ----
---------------------
-- Blur behind the bar, menus and notifications

for _, ns in ipairs({ "waybar", "rofi", "swaync-control-center", "swaync-notification-window", "quickshell-overview" }) do
    hl.layer_rule({
        name  = "blur-" .. ns,
        match = { namespace = "^" .. ns .. "$" },
        blur  = true,
        ignore_alpha = 0.3,
    })
end

-- Overview (Quickshell): it handles its own open/close animation
hl.layer_rule({
    name    = "overview-no-anim",
    match   = { namespace = "^quickshell-overview$" },
    no_anim = true,
})

hl.layer_rule({
    name  = "dim-rofi",
    match = { namespace = "^rofi$" },
    dim_around = true,
})
