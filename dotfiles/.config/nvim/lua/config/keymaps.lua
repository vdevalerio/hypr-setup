-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- <leader>cf formats the whole file (formatter + wrap at 80, see cleanup.lua);
-- in visual mode LazyVim's mapping formats just the selection
vim.keymap.set("n", "<leader>cf", "<cmd>FormatAll<cr>", { desc = "Format file (formatter + wrap at 80)" })
