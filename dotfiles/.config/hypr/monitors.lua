-------------------------------
---- AJUSTES POR MONITOR ------
-------------------------------
-- Feitos na central de controle → Displays (scripts/displays.sh) e guardados em
-- ~/.config/hypr/monitors.conf: uma seção por monitor, pela descrição (não muda se trocar de porta).
--   [Dell Inc. DELL SE2216H H5MNV91P138I]
--   position=1600x0   mode=1920x1080@60   scale=1.25   transform=1   mirror=eDP-1   disabled=true
-- O que não estiver lá segue o padrão de hyprland.lua (modo preferido, posição automática e a
-- escala de look.conf).

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

-- Escala padrão (SUPER + CTRL + ALT + = / -), de look.conf
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
    for desc, o in pairs(read_ini(HOME .. "/.config/hypr/monitors.conf")) do
        hl.monitor(spec("desc:" .. desc, o, scale))
    end
end

return M
