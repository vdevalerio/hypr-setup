-- Tema: Catppuccin com fundo transparente e paleta vinda do wallpaper.
-- ~/.config/hypr/colors.lua é gerado pelo tema atual (~/.config/hypr/themes/theme.py) com os mesmos
-- nomes da paleta Catppuccin; quando ele muda, o Neovim recolore sozinho.

local colors_file = vim.fn.expand("~/.config/hypr/colors.lua")

local function wallpaper_palette()
  local ok, c = pcall(dofile, colors_file)
  if not ok or type(c) ~= "table" then
    return {}
  end
  local palette = {}
  for name, hex in pairs(c) do
    if type(hex) == "string" and hex:match("^%x%x%x%x%x%x$") then
      palette[name] = "#" .. hex
    end
  end
  return palette
end

-- Remove fundos que sobrarem (vale para qualquer colorscheme)
local transparent_groups = {
  "Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle", "SignColumn",
  "FoldColumn", "LineNr", "CursorLineNr", "EndOfBuffer", "StatusLine", "StatusLineNC",
  "WinBar", "WinBarNC", "MsgArea", "WinSeparator",
}
local function clear_backgrounds()
  for _, group in ipairs(transparent_groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg, hl.ctermbg = nil, nil
    vim.api.nvim_set_hl(0, group, hl)
  end
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      float = { transparent = true, solid = false },
      term_colors = true,
      color_overrides = { mocha = wallpaper_palette() },
      styles = { comments = { "italic" }, keywords = { "italic" } },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)

      vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_backgrounds })

      -- Observa a pasta (o arquivo é substituído a cada troca de wallpaper)
      local watcher = vim.uv.new_fs_event()
      local pending = false
      watcher:start(vim.fs.dirname(colors_file), {}, function(_, fname)
        if fname ~= "colors.lua" or pending then
          return
        end
        pending = true
        vim.defer_fn(function()
          pending = false
          opts.color_overrides = { mocha = wallpaper_palette() }
          require("catppuccin").setup(opts)
          if (vim.g.colors_name or ""):match("^catppuccin") then
            vim.cmd.colorscheme(vim.g.colors_name)
          end
        end, 300)
      end)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
