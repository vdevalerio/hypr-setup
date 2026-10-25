-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Python: basedpyright (more complete than pyright) + ruff (lint/format)
vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"

-- Tools installed with `uv tool` (e.g. jupytext) live in ~/.local/bin;
-- make sure Neovim finds them even when launched outside the terminal.
local local_bin = vim.fn.expand("~/.local/bin")
if not vim.env.PATH:find(local_bin, 1, true) then
  vim.env.PATH = local_bin .. ":" .. vim.env.PATH
end

local opt = vim.opt
opt.colorcolumn = "80" -- always-on ruler at column 80
opt.scrolloff = 8
opt.wrap = false

-- LazyVim formats the whole file on save; cleanup.lua handles changed lines only
-- (use <leader>cf to format the whole file on demand).
vim.g.autoformat = false

-- Spell checking: English + Brazilian Portuguese. `zg` adds a word to the first spellfile (en),
-- `2zg` to the second (pt); both live in the config so they are versioned with the repo.
opt.spelllang = { "en", "pt_br" }
opt.spellfile = {
  vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
  vim.fn.stdpath("config") .. "/spell/pt.utf-8.add",
}
