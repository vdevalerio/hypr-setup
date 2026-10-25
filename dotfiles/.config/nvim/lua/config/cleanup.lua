-- Whitespace cleanup + re-indent: on save for the lines changed since the last write,
-- and on demand for the whole file. Changed lines = buffer vs. the file on disk (no git needed).
local M = {}

-- Filetypes where `=` would only damage the text (prose, patches)
local no_indent = { markdown = true, text = true, help = true, diff = true, gitcommit = true }

local function trim(first, last)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  for i, l in ipairs(lines) do
    -- Markdown: two trailing spaces are a hard line break
    local keep = vim.bo.filetype == "markdown" and l:match("[^%s]  $")
    if not keep then lines[i] = l:gsub("%s+$", "") end
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end

local function indent(first, last)
  if no_indent[vim.bo.filetype] or vim.bo.buftype ~= "" then return end
  vim.cmd(("silent keepjumps keeppatterns %d,%dnormal! =="):format(first, last))
end

local function each_range(ranges, fn)
  local view = vim.fn.winsaveview()
  for _, r in ipairs(ranges) do fn(r[1], r[2]) end
  vim.fn.winrestview(view)
end

-- Line ranges of the buffer that differ from the file on disk
local function changed_ranges()
  local name = vim.api.nvim_buf_get_name(0)
  local new = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if vim.fn.filereadable(name) ~= 1 then return { { 1, #new } } end
  local old = vim.fn.readfile(name)
  local hunks = vim.diff(table.concat(old, "\n") .. "\n", table.concat(new, "\n") .. "\n", { result_type = "indices" })
  local out = {}
  for _, h in ipairs(hunks) do
    if h[4] > 0 then out[#out + 1] = { h[3], h[3] + h[4] - 1 } end
  end
  return out
end

function M.changed()
  each_range(changed_ranges(), function(a, b) trim(a, b); indent(a, b) end)
end

function M.all(what)
  local last = vim.api.nvim_buf_line_count(0)
  each_range({ { 1, last } }, function(a, b)
    if what ~= "indent" then trim(a, b) end
    if what ~= "trim" then indent(a, b) end
  end)
end

function M.setup()
  vim.g.clean_on_save = true
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("clean_changed_lines", { clear = true }),
    callback = function()
      if vim.g.clean_on_save and vim.bo.modifiable then M.changed() end
    end,
  })
  vim.api.nvim_create_user_command("CleanTrim", function() M.all("trim") end, { desc = "Trim trailing whitespace (whole file)" })
  vim.api.nvim_create_user_command("CleanIndent", function() M.all("indent") end, { desc = "Re-indent (whole file)" })
  vim.api.nvim_create_user_command("CleanAll", function() M.all() end, { desc = "Trim and re-indent (whole file)" })
  local map = vim.keymap.set
  map("n", "<leader>cw", "<cmd>CleanTrim<cr>", { desc = "Trim trailing whitespace (file)" })
  map("n", "<leader>ci", "<cmd>CleanIndent<cr>", { desc = "Re-indent (file)" })
  map("n", "<leader>cW", "<cmd>CleanAll<cr>", { desc = "Trim + re-indent (file)" })
  map("n", "<leader>uW", function()
    vim.g.clean_on_save = not vim.g.clean_on_save
    vim.notify("Clean changed lines on save: " .. (vim.g.clean_on_save and "on" or "off"))
  end, { desc = "Toggle clean-on-save" })
end

return M
