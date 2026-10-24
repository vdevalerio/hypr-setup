-- ╭──────────────────────────────────────────────────────────╮
-- │  Hyprland — cores geradas do wallpaper (colors.lua)      │
-- │  Atalhos em binds.lua · Regras em rules.lua              │
-- │  SUPER + F1 mostra todos os atalhos                      │
-- ╰──────────────────────────────────────────────────────────╯

local c = require("colors")

-- Ajustes feitos pelos atalhos (fonte, gaps, escala) — veja scripts/look.sh
local look = { font = 100, gaps = 5, scale = "auto" }
do
    local f = io and io.open and io.open(os.getenv("HOME") .. "/.config/hypr/look.conf", "r")
    if f then
        for line in f:lines() do
            local k, v = line:match("^(%w+)=(%S+)")
            if k then look[k] = tonumber(v) or v end
        end
        f:close()
    end
end

------------------
---- MONITORS ----
------------------

-- Use `hyprctl monitors` para ver os nomes e ajustar se precisar
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = look.scale, -- SUPER + CTRL + ALT + = / - (ou na central de controle)
})

-- Ajustes por monitor (posição, resolução, escala, rotação...): central de controle → Displays
require("monitors").apply()


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME",   "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE",    "24")
hl.env("HYPRCURSOR_THEME","Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")

-- Editor padrão (usado pelo yazi e outros apps abertos fora do shell)
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")

-- Agente SSH do gnome-keyring (gcr-ssh-agent.socket): carrega as chaves de ~/.ssh e guarda a senha
-- no chaveiro, que o SDDM destrava no login. git/ssh pedem a senha da chave no máximo uma vez.
hl.env("SSH_AUTH_SOCK", (os.getenv("XDG_RUNTIME_DIR") or "/run/user/1000") .. "/gcr/ssh")

hl.env("QT_QPA_PLATFORM",    "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- cores do tema em ~/.config/qt6ct (geradas por theme.py)
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND",        "wayland,x11,*")
hl.env("SDL_VIDEODRIVER",    "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Idiomas do teclado (fcitx5: português, inglês, russo, japonês). GTK usa o protocolo
-- nativo do Wayland, por isso GTK_IM_MODULE não é definido. Brave/Claude: ~/.config/*-flags.conf
hl.env("XMODIFIERS",     "@im=fcitx")
hl.env("QT_IM_MODULE",   "fcitx")
hl.env("QT_IM_MODULES",  "wayland;fcitx")
hl.env("SDL_IM_MODULE",  "fcitx")
hl.env("GLFW_IM_MODULE", "ibus") -- kitty

-- Notebook híbrido: a GPU integrada renderiza o desktop para economizar bateria,
-- a dedicada (NVIDIA) fica disponível para apps pesados via `prime-run <app>`.
-- Os links /dev/dri/igpu e /dev/dri/dgpu são criados por uma regra udev (install.sh).
-- Em PCs com uma GPU só, nada disso é usado.
local function dev_exists(path)
    if not (io and io.open) then return false end
    local f, _, errno = io.open(path, "r")
    if f then f:close() return true end
    return errno ~= 2 -- ENOENT; "permission denied" significa que existe
end

local function first_existing(paths)
    for _, p in ipairs(paths) do
        if dev_exists(p) then return p end
    end
end

local igpu = first_existing({ "/dev/dri/igpu", "/dev/dri/amd-igpu" })
local dgpu = first_existing({ "/dev/dri/dgpu", "/dev/dri/nvidia-dgpu" })
if igpu then
    hl.env("AQ_DRM_DEVICES", dgpu and (igpu .. ":" .. dgpu) or igpu)
end


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/bar.sh") -- Waybar (reinicia sozinha se travar)
    hl.exec_cmd("~/.config/hypr/scripts/igpu.sh swaync") -- notificações (na GPU integrada)
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh restore") -- wallpaper animado + cores
    hl.exec_cmd("hypridle")
    hl.exec_cmd("~/.config/hypr/scripts/battery-watch.sh") -- avisos de bateria baixa
    hl.exec_cmd("~/.config/hypr/scripts/lid.sh check")     -- ligou com a tampa fechada e monitor externo
    hl.exec_cmd("fcitx5 -d --replace") -- idiomas do teclado (SUPER + CTRL + Espaço)
    hl.exec_cmd("~/.config/hypr/scripts/look.sh apply") -- tamanho das fontes (GTK, barra, menus...)
    hl.exec_cmd("~/.config/hypr/scripts/sddm-sync.sh")  -- tela de login igual à de bloqueio
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("udiskie --no-tray") -- monta pendrive/HD externo sozinho (avisa por notificação)
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- Tema escuro para apps GTK/libadwaita
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'") -- escala: look.sh
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        -- SUPER + CTRL + = / - ajustam; gaps_out segue gaps_in (5 → 12), igual ao look.sh
        gaps_in  = look.gaps,
        gaps_out = math.floor(look.gaps * 2.4 + 0.5),

        border_size = 2,

        col = {
            active_border   = { colors = { c.rgba(c.mauve, "ee"), c.rgba(c.blue, "ee") }, angle = 45 },
            inactive_border = c.rgba(c.surface1, "aa"),
        },

        -- Amigável ao mouse: redimensionar arrastando bordas, "grudar" janelas flutuantes
        resize_on_border       = true,
        extend_border_grab_area = 15,
        hover_icon_on_border   = true,
        snap = {
            enabled = true,
        },

        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.95,

        shadow = {
            enabled      = true,
            range        = 18,
            render_power = 3,
            color        = 0x88000000,
            color_inactive = 0x44000000,
        },

        blur = {
            enabled  = true,
            size     = 7,
            passes   = 2,
            vibrancy = 0.18,
            popups   = true,
        },
    },

    group = {
        col = {
            border_active   = c.rgba(c.peach, "ee"),
            border_inactive = c.rgba(c.surface1, "aa"),
        },
        groupbar = {
            font_family = "JetBrainsMono Nerd Font",
            font_size   = math.floor(11 * look.font / 100 + 0.5),
            height      = 18,
            gradients   = true,
            rounding    = 6,
            text_color  = c.rgba(c.crust, "ff"),
            col = {
                active   = c.rgba(c.peach, "dd"),
                inactive = c.rgba(c.overlay0, "aa"),
            },
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 3,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,  bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })


-----------------
---- LAYOUTS ----
-----------------

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        focus_on_activate       = true,
        -- Abrir um app gráfico pelo terminal "engole" o terminal enquanto o app estiver aberto
        enable_swallow          = true,
        swallow_regex           = "^(kitty)$",
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
    },

    cursor = {
        hide_on_key_press = false,
    },

    ecosystem = {
        no_donation_nag = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "br",
        kb_model   = "abnt2",
        kb_variant = "",
        kb_options = "",

        numlock_by_default = true,
        repeat_delay = 300,
        repeat_rate  = 35,

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor        = 0.6,
        },
    },
})

-- Touchpad: 3 dedos na horizontal troca de workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


require("binds")
require("rules")

-- Workspaces por monitor; ao conectar/desconectar um monitor, reorganiza e reinicia o
-- wallpaper animado (cada monitor tem o seu mpvpaper)
local workspaces = require("workspaces")
workspaces.setup()
hl.on("monitor.added", function()
    workspaces.setup()
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh restore")
end)
hl.on("monitor.removed", function()
    workspaces.setup()
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh restore") -- encerra o mpvpaper do monitor que saiu
    hl.exec_cmd("~/.config/hypr/scripts/lid.sh check") -- tampa fechada e tirou o monitor: liga a tela do notebook
end)
