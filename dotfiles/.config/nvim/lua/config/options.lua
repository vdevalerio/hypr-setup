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
opt.colorcolumn = "89" -- ruff line length limit (88)
opt.scrolloff = 8
opt.wrap = false
