-------------------------------
---- PER-MONITOR SETTINGS -----
-------------------------------
-- Made in the control center → Displays (scripts/displays.sh) and stored in
-- ~/.config/hypr/monitors.conf: one section per monitor, by description (doesn't change if you switch ports).
--   [Dell Inc. DELL SE2216H H5MNV91P138I]
--   position=1600x0   mode=1920x1080@60   scale=1.25   transform=1   mirror=eDP-1   disabled=true
-- Anything not listed there follows the hyprland.lua defaults (preferred mode, automatic position
-- and the scale from look.conf).
-- On battery, the laptop screen drops to 60 Hz (unless monitors.conf pins a mode): it is one of the
-- biggest power drains. scripts/power.sh reloads the config when the charger state changes.

local M = {}
local HOME = os.getenv("HOME")

local function read_ini(path)
    local t, cur = {}, nil
    local f = io and io.open and io.open(path, "r")
    if not f then return t end
    for line in f:lines() do
        local sec = line:match("^%[(.+)%]%s*$")
        if sec then
            cur = {}
            t[sec] = cur
        elseif cur then
            local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
            if k then cur[k] = v end
        end
    end
    f:close()
    return t
end

-- Default scale (SUPER + CTRL + ALT + = / -), from look.conf
local function default_scale()
    local s
    local f = io and io.open and io.open(HOME .. "/.config/hypr/look.conf", "r")
    if f then
        for line in f:lines() do
            local v = line:match("^scale=(%S+)")
            if v then s = v end
        end
        f:close()
    end
    return tonumber(s) or "auto"
end

local function on_battery()
    for _, bat in ipairs({ "BAT0", "BAT1", "BAT2" }) do
        local f = io and io.open and io.open("/sys/class/power_supply/" .. bat .. "/status", "r")
        if f then
            local status = f:read("l")
            f:close()
            return status == "Discharging"
        end
    end
    return false
end

local function internal(name)
    return name:match("^eDP") or name:match("^LVDS") or name:match("^DSI")
end

local function spec(output, o, scale)
    local s = {
        output   = output,
        mode     = o.mode or "preferred",
        position = o.position or "auto",
        scale    = tonumber(o.scale) or scale,
    }
    if o.transform then s.transform = tonumber(o.transform) end
    if o.mirror    then s.mirror = o.mirror end
    if o.disabled == "true" then s.disabled = true end
    return s
end

function M.apply()
    local scale = default_scale()
    local conf = read_ini(HOME .. "/.config/hypr/monitors.conf")
    if on_battery() and hl.get_monitors then
        for _, m in ipairs(hl.get_monitors()) do
            if internal(m.name) then
                local o = conf[m.description] or {}
                conf[m.description] = o
                o.mode = o.mode or string.format("%dx%d@60", m.width, m.height)
            end
        end
    end
    for desc, o in pairs(conf) do
        hl.monitor(spec("desc:" .. desc, o, scale))
    end
end

return M
