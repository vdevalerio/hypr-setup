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
-- `2zg` to the second (pt), `3zg` to the third (tech: technical terms, kept apart from the languages);
-- all live in the config so they are versioned with the repo (except the private list, see below).
opt.spelllang = { "en", "pt_br" }
local spellfiles = {
  vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
  vim.fn.stdpath("config") .. "/spell/pt.utf-8.add",
  vim.fn.stdpath("config") .. "/spell/tech.utf-8.add",
}
-- Fourth list, `4zg`: private words (client/company names). It lives outside the repo, in
-- ~/.config/hypr-setup/private.spell.add (install.sh keeps it in the git-ignored private/ folder).
local private_words = vim.fn.expand("~/.config/hypr-setup/private.spell.add")
if vim.uv.fs_stat(private_words) then
  table.insert(spellfiles, private_words)
end
opt.spellfile = spellfiles

-- Word lists are plain text; Neovim only uses their compiled .spl (git-ignored), so build any
-- that is missing or older than its list.
for _, add in ipairs(vim.opt.spellfile:get()) do
  local spl = add .. ".spl"
  local a, s = vim.uv.fs_stat(add), vim.uv.fs_stat(spl)
  if a and (not s or s.mtime.sec < a.mtime.sec) then
    vim.cmd("silent! mkspell! " .. vim.fn.fnameescape(add))
  end
end
