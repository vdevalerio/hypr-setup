-------------------------------------
---- WORKSPACES PER MONITOR ---------
-------------------------------------
-- Each monitor has its own workspaces 1–10 (SUPER + 1…0 applies to the focused monitor).
-- Internally, the laptop screen uses workspaces 1–10 and the other monitors (in connector
-- order: DP-1, HDMI-A-1…) use 11–20, 21–30… The order doesn't depend on position, so the
-- workspaces don't swap monitors when you reposition the screens.
-- Waybar shows 1–10 on each monitor (format-icons in waybar/config.jsonc).

local W = {}

-- Laptop first, then the others by connector name
local function internal(m) return m.name:match("^eDP") or m.name:match("^LVDS") or m.name:match("^DSI") end
local function sorted_monitors()
    local mons = hl.get_monitors()
    table.sort(mons, function(a, b)
        if (internal(a) ~= nil) ~= (internal(b) ~= nil) then return internal(a) ~= nil end
        return a.name < b.name
    end)
    return mons
end

-- First id of the monitor's set (0, 10, 20…)
function W.base(mon)
    mon = mon or hl.get_active_monitor()
    if not mon then return 0 end
    for i, m in ipairs(sorted_monitors()) do
        if m.name == mon.name then return (i - 1) * 10 end
    end
    return 0
end

-- Workspace n (1–10) of the focused monitor
function W.id(n) return W.base() + n end

-- First empty workspace of the focused monitor
function W.first_empty()
    local base = W.base()
    for n = 1, 10 do
        local ws = hl.get_workspace(base + n)
        if not ws or #ws:get_windows() == 0 then return base + n end
    end
    return base + 10
end

-- Rules (1–5 of each monitor always stay on the bar) and each monitor in its own set.
-- Called when the config loads and when a monitor is connected/disconnected.
local rules = {}
function W.setup()
    for _, r in ipairs(rules) do pcall(function() r:set_enabled(false) end) end
    rules = {}
    local active = hl.get_active_monitor()
    local moved = false
    for i, m in ipairs(sorted_monitors()) do
        local base = (i - 1) * 10
        for n = 1, 10 do
            table.insert(rules, hl.workspace_rule({
                workspace  = tostring(base + n),
                monitor    = m.name,
                persistent = n <= 5,
                default    = n == 1,
            }))
        end
        -- A monitor showing a workspace from another set (e.g. just connected) goes to its own 1
        local ws = m.active_workspace and m.active_workspace.id or 0
        if ws > 0 and (ws <= base or ws > base + 10) then
            hl.dispatch(hl.dsp.focus({ monitor = m.name }))
            hl.dispatch(hl.dsp.focus({ workspace = base + 1 }))
            moved = true
        end
    end
    if moved and active then hl.dispatch(hl.dsp.focus({ monitor = active.name })) end
end

return W
