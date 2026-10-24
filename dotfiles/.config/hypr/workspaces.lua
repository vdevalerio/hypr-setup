-------------------------------------
---- WORKSPACES POR MONITOR ---------
-------------------------------------
-- Cada monitor tem seus próprios workspaces 1–10 (SUPER + 1…0 vale para o monitor em foco).
-- Por dentro, a tela do notebook usa os workspaces 1–10 e os outros monitores (em ordem de
-- conector: DP-1, HDMI-A-1…) 11–20, 21–30… A ordem não depende da posição, para os workspaces
-- não trocarem de monitor quando você reposiciona as telas.
-- A Waybar mostra 1–10 em cada monitor (format-icons em waybar/config.jsonc).

local W = {}

-- Notebook primeiro, depois os outros pelo nome do conector
local function internal(m) return m.name:match("^eDP") or m.name:match("^LVDS") or m.name:match("^DSI") end
local function sorted_monitors()
    local mons = hl.get_monitors()
    table.sort(mons, function(a, b)
        if (internal(a) ~= nil) ~= (internal(b) ~= nil) then return internal(a) ~= nil end
        return a.name < b.name
    end)
    return mons
end

-- Primeiro id do conjunto do monitor (0, 10, 20…)
function W.base(mon)
    mon = mon or hl.get_active_monitor()
    if not mon then return 0 end
    for i, m in ipairs(sorted_monitors()) do
        if m.name == mon.name then return (i - 1) * 10 end
    end
    return 0
end

-- Workspace n (1–10) do monitor em foco
function W.id(n) return W.base() + n end

-- Primeiro workspace vazio do monitor em foco
function W.first_empty()
    local base = W.base()
    for n = 1, 10 do
        local ws = hl.get_workspace(base + n)
        if not ws or #ws:get_windows() == 0 then return base + n end
    end
    return base + 10
end

-- Regras (1–5 de cada monitor ficam sempre na barra) e cada monitor no seu conjunto.
-- Chamado ao carregar a config e quando um monitor é conectado/desconectado.
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
        -- Monitor mostrando um workspace de outro conjunto (ex.: recém-conectado) vai para o seu 1
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
