---------------------
---- KEYBINDINGS ----
---------------------
-- Every bind has a description: SUPER + F1 opens the searchable keybind list.

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


-- ── Applications ─────────────────────────────────────────────
bind(M("Return"),        hl.dsp.exec_cmd(terminal),                      "Open terminal")
bind(M("Space"),         hl.dsp.exec_cmd("pkill -x rofi || rofi -show drun"), "App launcher")
bind(M("D"),             hl.dsp.exec_cmd("pkill -x rofi || rofi -show drun"), "App launcher")
bind(M("SHIFT + Space"), hl.dsp.exec_cmd("pkill -x rofi || rofi -show run"),  "Run command")
bind("ALT + Tab",        hl.dsp.exec_cmd("pkill -x rofi || rofi -show window"), "Switch window (list)")
bind(M("Tab"),           hl.dsp.exec_cmd("~/.config/hypr/scripts/overview.sh"), "Workspace overview")
bind(M("CTRL + T"),      hl.dsp.exec_cmd("pkill -x rofi || ~/.config/hypr/scripts/todo.sh menu"), "To-do list")
bind(M("E"),             hl.dsp.exec_cmd(fileManager),                   "File manager")
bind(M("B"),             hl.dsp.exec_cmd(browser),                       "Web browser")
bind(M("V"),             hl.dsp.exec_cmd(scripts .. "clipboard.sh"),     "Clipboard history")
bind(M("SHIFT + V"),    hl.dsp.exec_cmd(scripts .. "voice.sh pick"),    "Text-to-speech voice (Piper)")
bind(M("semicolon"),     hl.dsp.exec_cmd("pkill -x rofi || rofi -show emoji -modi emoji"), "Emoji picker")
bind(M("equal"),         hl.dsp.exec_cmd("pkill -x rofi || rofi -show calc -modi calc -no-show-match -no-sort"), "Quick calculator")
bind(M("N"),            hl.dsp.exec_cmd("swaync-client -t -sw"),        "Notification center")
bind(M("SHIFT + N"),     hl.dsp.exec_cmd("swaync-client -C -sw"),        "Clear notifications")
bind(M("F1"),            hl.dsp.exec_cmd(scripts .. "keybinds.sh"),      "Show keybinds (this list)")
bind(M("SHIFT + B"),     hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"),       "Toggle bar")
bind(M("SHIFT + C"),     hl.dsp.exec_cmd("hyprpicker -a"),               "Color picker (copies hex)")

-- ── Wallpaper and colors ───────────────────────────────────────
bind(M("SHIFT + W"),     hl.dsp.exec_cmd(scripts .. "wallpaper.sh pick"),   "Choose wallpaper")
bind(M("CTRL + W"),      hl.dsp.exec_cmd(scripts .. "wallpaper.sh random"), "Random wallpaper")
bind(M("SHIFT + T"),     hl.dsp.exec_cmd(scripts .. "controlcenter.sh theme"), "Color theme (automatic or fixed)")

-- ── Control center and live tweaks (scripts/look.sh) ─
-- Values saved in ~/.config/hypr/look.conf (persist across restarts)
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

-- ── Keyboard language (fcitx5, scripts/keyboard.sh) ─────────
-- Hyprland keybinds stay on the br layout, whatever the active language.
bind(M("CTRL + Space"),         hl.dsp.exec_cmd(scripts .. "keyboard.sh next"), "Keyboard: next language")
bind(M("CTRL + SHIFT + Space"), hl.dsp.exec_cmd(scripts .. "keyboard.sh prev"), "Keyboard: previous language")
for i, lang in ipairs({ "Portuguese", "English", "Russian", "Japanese" }) do
    bind(M("CTRL + " .. i), hl.dsp.exec_cmd(scripts .. "keyboard.sh set " .. i), "Keyboard: " .. lang)
end

-- ── Session ──────────────────────────────────────────────────
bind(M("Escape"),        hl.dsp.exec_cmd("loginctl lock-session"),       "Lock screen")
bind(M("X"),             hl.dsp.exec_cmd(scripts .. "powermenu.sh"),     "Power menu")
bind(M("CTRL + Q"),      hl.dsp.exec_cmd("hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), "Exit Hyprland")

-- ── Laptop lid (with an external monitor, only the laptop screen turns off) ──
bind("switch:on:Lid Switch",  hl.dsp.exec_cmd(scripts .. "lid.sh close"), "Lid closed", { locked = true })
bind("switch:off:Lid Switch", hl.dsp.exec_cmd(scripts .. "lid.sh open"),  "Lid opened", { locked = true })

-- ── Screen recording and on-screen text ────────────────────────
bind(M("ALT + R"),         hl.dsp.exec_cmd(scripts .. "record.sh toggle"), "Record screen (start/stop)")
bind(M("ALT + SHIFT + R"), hl.dsp.exec_cmd(scripts .. "record.sh region"), "Record a region (start/stop)")
bind(M("CTRL + S"),        hl.dsp.exec_cmd(scripts .. "ocr.sh"),           "Copy text from screen area (OCR)")

-- ── Screenshots ─────────────────────────────────────────────
bind("Print",            hl.dsp.exec_cmd(scripts .. "screenshot.sh region"), "Screenshot: region")
bind("SHIFT + Print",    hl.dsp.exec_cmd(scripts .. "screenshot.sh screen"), "Screenshot: full screen")
bind(M("Print"),         hl.dsp.exec_cmd(scripts .. "screenshot.sh edit"),   "Screenshot: region + edit")
bind(M("SHIFT + S"),     hl.dsp.exec_cmd(scripts .. "screenshot.sh region"), "Screenshot: region")

-- ── Windows ─────────────────────────────────────────────────
bind(M("Q"),             hl.dsp.window.close(),                          "Close window")
bind(M("F"),             hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "Fullscreen")
bind(M("M"),             hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }), "Maximize")
bind(M("T"),             hl.dsp.window.float({ action = "toggle" }),     "Toggle floating/tiled")
bind(M("C"),             hl.dsp.window.center(),                         "Center floating window")
bind(M("P"),             hl.dsp.window.pin({ action = "toggle" }),       "Pin to all workspaces")
bind(M("Y"),             hl.dsp.layout("togglesplit"),                   "Toggle split direction")
bind(M("G"),             hl.dsp.group.toggle(),                          "Toggle tab group")
bind(M("ALT + Tab"),     hl.dsp.group.next(),                            "Next tab in group")
bind(M("ALT + SHIFT + Tab"), hl.dsp.group.prev(),                        "Previous tab in group")

-- Focus: arrows or h/j/k/l (vim style)
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

-- Resize mode: SUPER + R, then arrows/hjkl, Esc or Enter to exit
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

-- ── Workspaces (each monitor has its own 1–10, see workspaces.lua) ──
local ws = require("workspaces")
for i = 1, 10 do
    local key = i % 10 -- 10 = key 0
    bind(M(tostring(key)),     function() hl.dispatch(hl.dsp.focus({ workspace = ws.id(i) })) end,
         "Go to workspace " .. i .. " (this monitor)")
    bind(M("SHIFT + " .. key), function() hl.dispatch(hl.dsp.window.move({ workspace = ws.id(i) })) end,
         "Move window to workspace " .. i .. " (this monitor)")
end

-- m-1 / m+1: only the focused monitor's workspaces
bind(M("comma"),          hl.dsp.focus({ workspace = "m-1" }),           "Previous workspace")
bind(M("period"),         hl.dsp.focus({ workspace = "m+1" }),           "Next workspace")
bind(M("Page_Up"),        hl.dsp.focus({ workspace = "m-1" }),           "Previous workspace")
bind(M("Page_Down"),      hl.dsp.focus({ workspace = "m+1" }),           "Next workspace")
bind(M("apostrophe"),     hl.dsp.focus({ workspace = "previous" }),      "Back to last workspace")
bind(M("W"),              function() hl.dispatch(hl.dsp.focus({ workspace = ws.first_empty() })) end,
     "Go to empty workspace (this monitor)")

-- Multiple monitors
bind(M("O"),              hl.dsp.focus({ monitor = "+1" }),              "Focus next monitor")
bind(M("SHIFT + O"),      hl.dsp.window.move({ monitor = "+1" }),        "Move window to next monitor")

-- Scratchpad (a "hidden" workspace that shows up on top)
bind(M("S"),              hl.dsp.workspace.toggle_special("magic"),      "Toggle scratchpad")
bind(M("ALT + S"),        hl.dsp.window.move({ workspace = "special:magic" }), "Send window to scratchpad")

-- ── Mouse ───────────────────────────────────────────────────
bind(M("mouse_down"),     hl.dsp.focus({ workspace = "m+1" }),           "Next workspace (mouse wheel)")
bind(M("mouse_up"),       hl.dsp.focus({ workspace = "m-1" }),           "Previous workspace (mouse wheel)")
bind(M("mouse:272"),      hl.dsp.window.drag(),   "Drag window (left button)",  { mouse = true })
bind(M("mouse:273"),      hl.dsp.window.resize(), "Resize window (right button)",     { mouse = true })

-- ── Rofi menus close when clicking outside ─────────────────────
-- Rofi (a Wayland layer) only receives clicks inside its own area, so its "click-to-exit"
-- never fires. This bind doesn't consume the click: it only closes the menu if the cursor is outside it.
local function close_rofi_if_outside()
    local p = hl.get_cursor_pos()
    if not p then return end
    for _, l in ipairs(hl.get_layers({ namespace = "rofi" })) do
        if l.mapped and (p.x < l.x or p.x >= l.x + l.w or p.y < l.y or p.y >= l.y + l.h) then
            hl.exec_cmd("pkill -x rofi")
            return
        end
    end
end
bind("mouse:272", close_rofi_if_outside, "Close menu when clicking outside it", { non_consuming = true })
bind("mouse:273", close_rofi_if_outside, "Close menu when clicking outside it", { non_consuming = true })

-- ── Laptop media keys ─────────────────────────────
bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(scripts .. "osd.sh volume up"), "Volume up", { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(scripts .. "osd.sh volume down"), "Volume down", { locked = true, repeating = true })
bind("XF86AudioMute",         hl.dsp.exec_cmd(scripts .. "osd.sh volume mute"), "Mute",            { locked = true })
bind("XF86AudioMicMute",      hl.dsp.exec_cmd(scripts .. "osd.sh mic mute"), "Mute microphone", { locked = true })
-- Caps Lock: only notifies. Not a bind: Caps Lock itself changes the modifiers, so a bind wouldn't match.
-- Raw key event (xkb keycode 66 = Caps Lock); on release the LED is already in its new state.
-- The event arrives twice (physical keyboard + fcitx5 virtual keyboard) with the same timestamp: ignore the repeat.
local last_caps
hl.on("input.keyboard.key", function(keycode, time, state)
    if keycode == 66 and tostring(state) == "0" and time ~= last_caps then
        last_caps = time
        hl.exec_cmd(scripts .. "osd.sh caps")
    end
end)
-- Brightness: of the focused monitor (laptop or external with DDC/CI), see scripts/brightness.sh
bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scripts .. "brightness.sh up"),   "Brightness up (focused monitor)", { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "brightness.sh down"), "Brightness down (focused monitor)", { locked = true, repeating = true })
bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       "Next track",      { locked = true })
bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   "Previous track",  { locked = true })
bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause",      { locked = true })
bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause",      { locked = true })
