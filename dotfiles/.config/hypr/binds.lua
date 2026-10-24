---------------------
---- KEYBINDINGS ----
---------------------
-- Toda bind tem descrição (em inglês): SUPER + F1 abre a lista pesquisável de atalhos.

local mainMod = "SUPER"

local terminal    = "kitty"
local fileManager = "kitty --class yazi -e yazi"
local browser     = "brave"
local scripts     = "~/.config/hypr/scripts/"

local function bind(keys, dispatcher, desc, opts)
    opts = opts or {}
    opts.description = desc
    return hl.bind(keys, dispatcher, opts)
end

local function M(keys) return mainMod .. " + " .. keys end


-- ── Aplicativos ─────────────────────────────────────────────
bind(M("Return"),        hl.dsp.exec_cmd(terminal),                      "Open terminal")
bind(M("Space"),         hl.dsp.exec_cmd("pkill -x rofi || rofi -show drun"), "App launcher")
bind(M("D"),             hl.dsp.exec_cmd("pkill -x rofi || rofi -show drun"), "App launcher")
bind(M("SHIFT + Space"), hl.dsp.exec_cmd("pkill -x rofi || rofi -show run"),  "Run command")
bind("ALT + Tab",        hl.dsp.exec_cmd("pkill -x rofi || rofi -show window"), "Switch window (list)")
bind(M("E"),             hl.dsp.exec_cmd(fileManager),                   "File manager")
bind(M("B"),             hl.dsp.exec_cmd(browser),                       "Web browser")
bind(M("V"),             hl.dsp.exec_cmd(scripts .. "clipboard.sh"),     "Clipboard history")
bind(M("semicolon"),     hl.dsp.exec_cmd("pkill -x rofi || rofi -show emoji -modi emoji"), "Emoji picker")
bind(M("equal"),         hl.dsp.exec_cmd("pkill -x rofi || rofi -show calc -modi calc -no-show-match -no-sort"), "Quick calculator")
bind(M("N"),            hl.dsp.exec_cmd("swaync-client -t -sw"),        "Notification center")
bind(M("SHIFT + N"),     hl.dsp.exec_cmd("swaync-client -C -sw"),        "Clear notifications")
bind(M("F1"),            hl.dsp.exec_cmd(scripts .. "keybinds.sh"),      "Show keybinds (this list)")
bind(M("SHIFT + B"),     hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"),       "Toggle bar")
bind(M("SHIFT + C"),     hl.dsp.exec_cmd("hyprpicker -a"),               "Color picker (copies hex)")

-- ── Wallpaper e cores ───────────────────────────────────────
bind(M("SHIFT + W"),     hl.dsp.exec_cmd(scripts .. "wallpaper.sh pick"),   "Choose wallpaper")
bind(M("CTRL + W"),      hl.dsp.exec_cmd(scripts .. "wallpaper.sh random"), "Random wallpaper")
bind(M("SHIFT + T"),     hl.dsp.exec_cmd(scripts .. "controlcenter.sh theme"), "Color theme (automatic or fixed)")

-- ── Central de controle e ajustes ao vivo (scripts/look.sh) ─
-- Valores salvos em ~/.config/hypr/look.conf (continuam depois de reiniciar)
bind(M("A"),             hl.dsp.exec_cmd(scripts .. "controlcenter.sh"), "Control center")
bind(M("ALT + equal"),   hl.dsp.exec_cmd(scripts .. "look.sh font up"),    "Font size: bigger")
bind(M("ALT + minus"),   hl.dsp.exec_cmd(scripts .. "look.sh font down"),  "Font size: smaller")
bind(M("ALT + 0"),       hl.dsp.exec_cmd(scripts .. "look.sh font reset"), "Font size: reset")
bind(M("CTRL + equal"),  hl.dsp.exec_cmd(scripts .. "look.sh gaps up"),    "Window gaps: bigger",  { repeating = true })
bind(M("CTRL + minus"),  hl.dsp.exec_cmd(scripts .. "look.sh gaps down"),  "Window gaps: smaller", { repeating = true })
bind(M("CTRL + 0"),      hl.dsp.exec_cmd(scripts .. "look.sh gaps reset"), "Window gaps: reset")
bind(M("CTRL + ALT + equal"), hl.dsp.exec_cmd(scripts .. "look.sh scale up"),    "Display scale: bigger (everything)")
bind(M("CTRL + ALT + minus"), hl.dsp.exec_cmd(scripts .. "look.sh scale down"),  "Display scale: smaller (everything)")
bind(M("CTRL + ALT + 0"),     hl.dsp.exec_cmd(scripts .. "look.sh scale reset"), "Display scale: automatic")

-- ── Idioma do teclado (fcitx5, scripts/keyboard.sh) ─────────
-- Os atalhos do Hyprland continuam no layout br, qualquer que seja o idioma ativo.
bind(M("CTRL + Space"),         hl.dsp.exec_cmd(scripts .. "keyboard.sh next"), "Keyboard: next language")
bind(M("CTRL + SHIFT + Space"), hl.dsp.exec_cmd(scripts .. "keyboard.sh prev"), "Keyboard: previous language")
for i, lang in ipairs({ "Português", "English", "Russian", "Japanese" }) do
    bind(M("CTRL + " .. i), hl.dsp.exec_cmd(scripts .. "keyboard.sh set " .. i), "Keyboard: " .. lang)
end

-- ── Sessão ──────────────────────────────────────────────────
bind(M("Escape"),        hl.dsp.exec_cmd("loginctl lock-session"),       "Lock screen")
bind(M("X"),             hl.dsp.exec_cmd(scripts .. "powermenu.sh"),     "Power menu")
bind(M("CTRL + Q"),      hl.dsp.exec_cmd("hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), "Exit Hyprland")

-- ── Tampa do notebook (com monitor externo, desliga só a tela do notebook) ──
bind("switch:on:Lid Switch",  hl.dsp.exec_cmd(scripts .. "lid.sh close"), "Lid closed", { locked = true })
bind("switch:off:Lid Switch", hl.dsp.exec_cmd(scripts .. "lid.sh open"),  "Lid opened", { locked = true })

-- ── Gravação de tela e texto da tela ────────────────────────
bind(M("ALT + R"),         hl.dsp.exec_cmd(scripts .. "record.sh toggle"), "Record screen (start/stop)")
bind(M("ALT + SHIFT + R"), hl.dsp.exec_cmd(scripts .. "record.sh region"), "Record a region (start/stop)")
bind(M("CTRL + S"),        hl.dsp.exec_cmd(scripts .. "ocr.sh"),           "Copy text from screen area (OCR)")

-- ── Screenshots ─────────────────────────────────────────────
bind("Print",            hl.dsp.exec_cmd(scripts .. "screenshot.sh region"), "Screenshot: region")
bind("SHIFT + Print",    hl.dsp.exec_cmd(scripts .. "screenshot.sh screen"), "Screenshot: full screen")
bind(M("Print"),         hl.dsp.exec_cmd(scripts .. "screenshot.sh edit"),   "Screenshot: region + edit")
bind(M("SHIFT + S"),     hl.dsp.exec_cmd(scripts .. "screenshot.sh region"), "Screenshot: region")

-- ── Janelas ─────────────────────────────────────────────────
bind(M("Q"),             hl.dsp.window.close(),                          "Close window")
bind(M("F"),             hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "Fullscreen")
bind(M("M"),             hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }), "Maximize")
bind(M("T"),             hl.dsp.window.float({ action = "toggle" }),     "Toggle floating/tiled")
bind(M("C"),             hl.dsp.window.center(),                         "Center floating window")
bind(M("P"),             hl.dsp.window.pin({ action = "toggle" }),       "Pin to all workspaces")
bind(M("Y"),             hl.dsp.layout("togglesplit"),                   "Toggle split direction")
bind(M("G"),             hl.dsp.group.toggle(),                          "Toggle tab group")
bind(M("Tab"),           hl.dsp.group.next(),                            "Next tab in group")
bind(M("SHIFT + Tab"),   hl.dsp.group.prev(),                            "Previous tab in group")

-- Foco: setas ou h/j/k/l (estilo vim)
local dirs = {
    { "left",  "H", "left"  },
    { "right", "L", "right" },
    { "up",    "K", "up"    },
    { "down",  "J", "down"  },
}
local resize_step = {
    left  = { x = -40, y = 0 },
    right = { x =  40, y = 0 },
    up    = { x = 0,   y = -40 },
    down  = { x = 0,   y =  40 },
}

for _, d in ipairs(dirs) do
    local arrow, vim, dir = d[1], d[2], d[3]
    local rs = resize_step[dir]
    for _, key in ipairs({ arrow, vim }) do
        bind(M(key),            hl.dsp.focus({ direction = dir }),       "Focus " .. dir)
        bind(M("SHIFT + " .. key), hl.dsp.window.move({ direction = dir }), "Move window " .. dir)
        bind(M("CTRL + " .. key),  hl.dsp.window.resize({ x = rs.x, y = rs.y, relative = true }),
             "Resize window (" .. dir .. ")", { repeating = true })
    end
end

-- Modo de redimensionar: SUPER + R, depois setas/hjkl, Esc ou Enter para sair
bind(M("R"), hl.dsp.submap("resize"), "Resize mode (Esc to exit)")
hl.define_submap("resize", function()
    for _, d in ipairs(dirs) do
        local rs = resize_step[d[3]]
        for _, key in ipairs({ d[1], d[2] }) do
            hl.bind(key, hl.dsp.window.resize({ x = rs.x, y = rs.y, relative = true }), { repeating = true })
        end
    end
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

-- ── Workspaces (cada monitor tem os seus 1–10, veja workspaces.lua) ──
local ws = require("workspaces")
for i = 1, 10 do
    local key = i % 10 -- 10 = tecla 0
    bind(M(tostring(key)),     function() hl.dispatch(hl.dsp.focus({ workspace = ws.id(i) })) end,
         "Go to workspace " .. i .. " (this monitor)")
    bind(M("SHIFT + " .. key), function() hl.dispatch(hl.dsp.window.move({ workspace = ws.id(i) })) end,
         "Move window to workspace " .. i .. " (this monitor)")
end

-- m-1 / m+1: só os workspaces do monitor em foco
bind(M("comma"),          hl.dsp.focus({ workspace = "m-1" }),           "Previous workspace")
bind(M("period"),         hl.dsp.focus({ workspace = "m+1" }),           "Next workspace")
bind(M("Page_Up"),        hl.dsp.focus({ workspace = "m-1" }),           "Previous workspace")
bind(M("Page_Down"),      hl.dsp.focus({ workspace = "m+1" }),           "Next workspace")
bind(M("apostrophe"),     hl.dsp.focus({ workspace = "previous" }),      "Back to last workspace")
bind(M("W"),              function() hl.dispatch(hl.dsp.focus({ workspace = ws.first_empty() })) end,
     "Go to empty workspace (this monitor)")

-- Vários monitores
bind(M("O"),              hl.dsp.focus({ monitor = "+1" }),              "Focus next monitor")
bind(M("SHIFT + O"),      hl.dsp.window.move({ monitor = "+1" }),        "Move window to next monitor")

-- Scratchpad (workspace "escondido" que aparece por cima)
bind(M("S"),              hl.dsp.workspace.toggle_special("magic"),      "Toggle scratchpad")
bind(M("ALT + S"),        hl.dsp.window.move({ workspace = "special:magic" }), "Send window to scratchpad")

-- ── Mouse ───────────────────────────────────────────────────
bind(M("mouse_down"),     hl.dsp.focus({ workspace = "m+1" }),           "Next workspace (mouse wheel)")
bind(M("mouse_up"),       hl.dsp.focus({ workspace = "m-1" }),           "Previous workspace (mouse wheel)")
bind(M("mouse:272"),      hl.dsp.window.drag(),   "Drag window (left button)",  { mouse = true })
bind(M("mouse:273"),      hl.dsp.window.resize(), "Resize window (right button)",     { mouse = true })

-- ── Teclas de mídia do notebook ─────────────────────────────
bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(scripts .. "osd.sh volume up"), "Volume up", { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(scripts .. "osd.sh volume down"), "Volume down", { locked = true, repeating = true })
bind("XF86AudioMute",         hl.dsp.exec_cmd(scripts .. "osd.sh volume mute"), "Mute",            { locked = true })
bind("XF86AudioMicMute",      hl.dsp.exec_cmd(scripts .. "osd.sh mic mute"), "Mute microphone", { locked = true })
-- Caps Lock: só avisa. Não é bind: o próprio Caps Lock muda os modificadores e a bind não casa.
-- Evento cru da tecla (keycode xkb 66 = Caps Lock); ao soltar, o LED já está no estado novo.
-- O evento chega em dobro (teclado físico + teclado virtual do fcitx5) com o mesmo horário: ignora o repetido.
local last_caps
hl.on("input.keyboard.key", function(keycode, time, state)
    if keycode == 66 and tostring(state) == "0" and time ~= last_caps then
        last_caps = time
        hl.exec_cmd(scripts .. "osd.sh caps")
    end
end)
-- Brilho: do monitor em foco (notebook ou externo com DDC/CI), veja scripts/brightness.sh
bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scripts .. "brightness.sh up"),   "Brightness up (focused monitor)", { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "brightness.sh down"), "Brightness down (focused monitor)", { locked = true, repeating = true })
bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       "Next track",      { locked = true })
bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   "Previous track",  { locked = true })
bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause",      { locked = true })
bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause",      { locked = true })
