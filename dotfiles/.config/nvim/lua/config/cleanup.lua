-- Whitespace cleanup + re-indent/wrap at column 80: on save for the lines changed since the last write,
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

-- Formatters (wrapping at column 80) that can format a line range; the others would rewrite the
-- whole file, so they are left to <leader>cf.
local function range_formatters()
  local ok, conform = pcall(require, "conform")
  if not ok then return nil end
  local list = conform.list_formatters(0)
  if #list == 0 then return nil end
  for _, f in ipairs(list) do
    local cfg = conform.get_formatter_config(f.name, 0)
    if not (cfg and cfg.range_args) then return nil end
  end
  return conform
end

-- Formatters never rewrap comments (ruff leaves them alone): hard-wrap the full-line `#` comments
-- longer than column 80 with gq (the `comments` option keeps the indent and the `#` leader).
local function wrap_comments(first, last)
  if vim.bo.filetype ~= "python" then return end
  local tw, fe = vim.bo.textwidth, vim.bo.formatexpr
  vim.bo.textwidth, vim.bo.formatexpr = 80, "" -- LazyVim's formatexpr would hand gq to a formatter
  for l = last, first, -1 do
    local text = vim.api.nvim_buf_get_lines(0, l - 1, l, false)[1] or ""
    -- skip shebangs, cell markers (# %%) and tool pragmas (# noqa, # type:, # fmt:)
    local plain = text:match("^%s*#%s") and not text:match("^%s*#%s*%%%%")
      and not text:match("^%s*#%s*[%w_]+:%s") and not text:match("^%s*#%s*noqa")
    if plain and vim.fn.strdisplaywidth(text) > 80 then
      vim.cmd(("silent keepjumps keeppatterns %dnormal! gqq"):format(l))
    end
  end
  vim.bo.textwidth, vim.bo.formatexpr = tw, fe
end

-- Docstrings (a string that is a whole statement) are text ruff leaves alone too. A paragraph with a
-- line longer than column 80 is re-filled to 80; paragraphs laid out in columns (runs of spaces
-- inside a line: tables, examples) only get their long lines broken, never joined.
local function fill(par)
  local lead1 = par[1]:match("^%s*")
  local lead = #par > 1 and par[2]:match("^%s*") or lead1
  local aligned = false
  for _, l in ipairs(par) do
    if l:gsub("^%s+", ""):match("%S%s%s+%S") then aligned = true end
  end
  local out = {}
  local function emit(words, first_lead, hang)
    local cur = first_lead
    local empty = true
    for _, w in ipairs(words) do
      if not empty and vim.fn.strdisplaywidth(cur .. " " .. w) > 80 then
        out[#out + 1] = cur
        cur, empty = hang .. w, false
      else
        cur, empty = cur .. (empty and "" or " ") .. w, false
      end
    end
    out[#out + 1] = cur
  end
  if aligned then
    for _, l in ipairs(par) do
      local li, text = l:match("^%s*"), l
      while vim.fn.strdisplaywidth(text) > 80 do
        local cut
        for i = 80, #li + 2, -1 do
          if text:sub(i, i) == " " then cut = i break end
        end
        if not cut then break end -- a single word longer than the line
        out[#out + 1] = (text:sub(1, cut - 1):gsub("%s+$", ""))
        text = li .. "    " .. text:sub(cut + 1):gsub("^%s+", "")
      end
      out[#out + 1] = text
    end
  else
    local ws = {}
    for _, l in ipairs(par) do for w in l:gmatch("%S+") do ws[#ws + 1] = w end end
    emit(ws, lead1, lead)
  end
  return out
end

local function wrap_docstrings(first, last)
  if vim.bo.filetype ~= "python" then return end
  local ok, parser = pcall(vim.treesitter.get_parser, 0, "python")
  if not ok or not parser then return end
  local root = parser:parse()[1]:root()
  local found = {}
  local function visit(node)
    if node:type() == "expression_statement" and node:named_child_count() == 1
      and node:named_child(0):type() == "string" then
      local sr, _, er = node:range()
      -- only triple-quoted: breaking a one-line "string" would be a syntax error
      local head = vim.treesitter.get_node_text(node, 0):match("^%a*(['\"]['\"]['\"])")
      if head then found[#found + 1] = { sr + 1, er + 1 } end
    end
    for child in node:iter_children() do visit(child) end
  end
  visit(root)
  table.sort(found, function(a, b) return a[1] > b[1] end) -- bottom-up: wrapping shifts the lines below
  for _, f in ipairs(found) do
    local lines = vim.api.nvim_buf_get_lines(0, f[1] - 1, f[2], false)
    local res, par, long, touched = {}, {}, false, false
    local function flush(at)
      if #par > 0 then
        local pend = at - 1
        local pstart = pend - #par + 1
        if long and pend + f[1] - 1 >= first and pstart + f[1] - 1 <= last then
          vim.list_extend(res, fill(par)) touched = true
        else
          vim.list_extend(res, par)
        end
      end
      par, long = {}, false
    end
    for i, l in ipairs(lines) do
      -- blank lines and the closing quotes end a paragraph
      if l:match("^%s*$") or (i == #lines and l:match('^%s*"""%s*$')) then
        flush(i) res[#res + 1] = l
      else
        par[#par + 1] = l
        if vim.fn.strdisplaywidth(l) > 80 then long = true end
      end
    end
    flush(#lines + 1)
    if touched then vim.api.nvim_buf_set_lines(0, f[1] - 1, f[2], false, res) end
  end
end

local function indent(first, last)
  if no_indent[vim.bo.filetype] or vim.bo.buftype ~= "" then return end
  local conform = range_formatters()
  if conform then
    local line = vim.api.nvim_buf_get_lines(0, last - 1, last, false)[1] or ""
    local done = conform.format({
      async = false, timeout_ms = 3000, lsp_format = "never",
      range = { start = { first, 0 }, ["end"] = { last, #line } },
    })
    if done then wrap_comments(first, last) wrap_docstrings(first, last) return end
  end
  vim.cmd(("silent keepjumps keeppatterns %d,%dnormal! =="):format(first, last))
  wrap_comments(first, last)
  wrap_docstrings(first, last)
end

local function each_range(ranges, fn)
  local view = vim.fn.winsaveview()
  for i = #ranges, 1, -1 do fn(ranges[i][1], ranges[i][2]) end
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

-- Whole file with any available formatter (range-capable or not, LSP as fallback), wrapping at
-- column 80; plain re-indent when there is none.
function M.format_all()
  local view = vim.fn.winsaveview()
  local last = vim.api.nvim_buf_line_count(0)
  trim(1, last)
  if vim.bo.filetype == "text" then
    -- Plain prose: hard-wrap every paragraph at column 80
    local tw, fe = vim.bo.textwidth, vim.bo.formatexpr
    vim.bo.textwidth, vim.bo.formatexpr = 80, "" -- LazyVim's formatexpr would hand gq to a formatter
    vim.cmd("silent keepjumps keeppatterns normal! gggqG")
    vim.bo.textwidth, vim.bo.formatexpr = tw, fe
  else
    local ok, conform = pcall(require, "conform")
    -- markdown goes through prettier (code blocks and tables stay intact); other prose is skipped
    local skip = no_indent[vim.bo.filetype] and vim.bo.filetype ~= "markdown"
    local done = ok and not skip
      and conform.format({ async = false, timeout_ms = 5000, lsp_format = "fallback" })
    if done then
      local n = vim.api.nvim_buf_line_count(0)
      wrap_comments(1, n)
      wrap_docstrings(1, n)
    elseif not no_indent[vim.bo.filetype] then indent(1, last) end
  end
  vim.fn.winrestview(view)
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
  vim.api.nvim_create_user_command("CleanIndent", function() M.all("indent") end, { desc = "Re-indent and wrap at column 80 (whole file)" })
  vim.api.nvim_create_user_command("CleanAll", function() M.all() end, { desc = "Trim and re-indent (whole file)" })
  vim.api.nvim_create_user_command("FormatAll", M.format_all, { desc = "Format the whole file (formatter, wrap at 80)" })
  local map = vim.keymap.set
  map("n", "<leader>cw", "<cmd>CleanTrim<cr>", { desc = "Trim trailing whitespace (file)" })
  map("n", "<leader>ci", "<cmd>CleanIndent<cr>", { desc = "Re-indent + wrap at 80 (file)" })
  map("n", "<leader>cW", "<cmd>CleanAll<cr>", { desc = "Trim + re-indent + wrap (file)" })
  map("n", "<leader>cg", "<cmd>FormatAll<cr>", { desc = "Format whole file (global)" })
  map("n", "<leader>uW", function()
    vim.g.clean_on_save = not vim.g.clean_on_save
    vim.notify("Clean changed lines on save: " .. (vim.g.clean_on_save and "on" or "off"))
  end, { desc = "Toggle clean-on-save" })
end

return M
