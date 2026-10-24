--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- Descubra a "class" de uma janela com: hyprctl clients

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Corrige problemas de arrastar no XWayland
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

-- Utilitários abrem flutuando e centralizados
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|blueman-manager|nm-connection-editor|org.gnome.FileRoller|file-roller|nwg-look|qt6ct|btop-float|nmtui-float|xdg-desktop-portal-gtk|hyprland-share-picker|org.kde.polkit-kde-authentication-agent-1|hyprpolkitagent)$" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.5", "monitor_h*0.6" },
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

-- Gráficos do matplotlib (plt.show()) abrem flutuando
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

-- Picture-in-picture do navegador: fica fixo no canto, em todos os workspaces
hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture|Picture in picture|Imagem em imagem)$" },
    float = true,
    pin   = true,
    size  = { "monitor_w*0.28", "monitor_h*0.28" },
    move  = { "monitor_w*0.71", "monitor_h*0.69" },
    keep_aspect_ratio = true,
})

-- Não deixa a tela apagar durante vídeos em tela cheia
hl.window_rule({
    name  = "idle-inhibit-fullscreen",
    match = { class = ".*" },
    idle_inhibit = "fullscreen",
})

-- Terminal: a transparência fica no kitty (background_opacity); aqui só garante
-- opacidade total da janela para o texto não ficar apagado quando sem foco
hl.window_rule({
    name  = "kitty-opaque-text",
    match = { class = "^(kitty)$" },
    opacity = "1.0 override 1.0 override",
})


---------------------
---- LAYER RULES ----
---------------------
-- Desfoque (blur) atrás da barra, menus e notificações

for _, ns in ipairs({ "waybar", "rofi", "swaync-control-center", "swaync-notification-window" }) do
    hl.layer_rule({
        name  = "blur-" .. ns,
        match = { namespace = "^" .. ns .. "$" },
        blur  = true,
        ignore_alpha = 0.3,
    })
end

hl.layer_rule({
    name  = "dim-rofi",
    match = { namespace = "^rofi$" },
    dim_around = true,
})
