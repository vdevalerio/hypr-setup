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
  local ft = vim.bo.filetype
  if ft ~= "python" and not ft:match("sh$") then return end
  local tw, fe = vim.bo.textwidth, vim.bo.formatexpr
  vim.bo.textwidth, vim.bo.formatexpr = 80, "" -- LazyVim's formatexpr would hand gq to a formatter
  for l = last, first, -1 do
    local text = vim.api.nvim_buf_get_lines(0, l - 1, l, false)[1] or ""
    -- skip shebangs, cell markers (# %%) and tool pragmas (# noqa, # type:, # fmt:)
    local plain = text:match("^%s*#%s") and not text:match("^%s*#%s*%%%%")
      and not text:match("^%s*#%s*[%w_]+:%s") and not text:match("^%s*#%s*noqa")
    -- shell: column-aligned comments (usage tables) wrap with a hanging indent
    -- under their description column; the shebang is left alone
    local width = vim.bo.textwidth > 0 and vim.bo.textwidth or 80
    if plain and ft:match("sh$") and text:match("^#!") then plain = false end
    local hang = plain and ft:match("sh$") and text:match("^(%s*#%s*%S.-%S%s%s+)%S")
    if hang and vim.fn.strdisplaywidth(text) > width then
      local col = vim.fn.strdisplaywidth(hang)
      local pad = text:match("^%s*#") .. string.rep(" ", col - #text:match("^%s*#"))
      local new, rest = {}, text
      while vim.fn.strdisplaywidth(rest) > width do
        local cut
        for i = width + 1, col + 2, -1 do
          if rest:sub(i, i) == " " and rest:sub(i - 1, i - 1) ~= " " then cut = i break end
        end
        if not cut then break end
        new[#new + 1] = rest:sub(1, cut - 1)
        rest = pad .. rest:sub(cut + 1)
      end
      new[#new + 1] = rest
      vim.api.nvim_buf_set_lines(0, l - 1, l, false, new)
      plain = false
    elseif hang then
      plain = false
    end
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

function M.trim_all()
  trim(1, vim.api.nvim_buf_line_count(0))
end

-- Whole file with any available formatter (range-capable or not, LSP as fallback), wrapping at
-- column 80; plain re-indent when there is none.
-- Shell: shfmt never breaks long lines. Split each one that is wider than the width
-- (`max_line_length` from .editorconfig, default 80) with a trailing `\` at the last
-- safe spot: after ` && ` / ` || ` / ` | `, else between two words. Quotes, `${}`,
-- `$()`, comments and heredocs are never split; shfmt then re-indents the new lines.
local function sh_width() return vim.bo.textwidth > 0 and vim.bo.textwidth or 80 end

-- Split points of `line` as {col_after_which_to_break, is_operator}, quote-aware
local function sh_splits(line)
  local pts, stack, q, i, n, awkq = {}, {}, nil, 1, #line, false
  while i <= n do
    local c = line:sub(i, i)
    if q then
      if c == "\\" and q == '"' then i = i + 1
      elseif c == q then q = nil
      elseif awkq and c == " " and line:sub(i - 1, i - 1):match("[;}]") and i < n then
        -- an awk program may continue on the next line after `;` or `}`
        pts[#pts + 1] = { i - 1, 3 }
      end
    elseif c == "\\" then i = i + 1
    elseif c == "'" or c == '"' or c == "`" then
      q = c
      awkq = c == "'" and line:sub(1, i - 1):match("%f[%w]awk%s[^']*$") ~= nil
    elseif c == "$" and line:sub(i + 1, i + 1):match("[({]") then
      -- only a plain `$( … )` can be split inside; `$(( ))` and `${ }` cannot
      local open = line:sub(i + 1, i + 2)
      local split = open:sub(1, 1) == "(" and open ~= "(("
      stack[#stack + 1] = { open:sub(1, 1) == "(" and ")" or "}", split }
      i = i + 1
    elseif #stack > 0 and c == stack[#stack][1] then stack[#stack] = nil
    elseif #stack > 0 and c == "(" then stack[#stack + 1] = { ")", false }
    elseif c == "#" and #stack == 0 and (i == 1 or line:sub(i - 1, i - 1):match("%s")) then break
    elseif c == " " and (#stack == 0 or stack[#stack][2]) and i > 1 and not line:sub(i - 1, i - 1):match("%s") then
      local before = line:sub(1, i - 1)
      local op = before:match(" &&$") or before:match(" ||$") or before:match(" |$")
      local sep = before:match("[^\\];;?$")
      local nxt = line:sub(i + 1, i + 1)
      if nxt ~= "" and nxt ~= "#" and not before:match("\\$") then
        -- priority: `;` / `;;` (new line, no `\`) > && || | > any space
        pts[#pts + 1] = { i - 1, sep and 3 or op and 2 or 1 }
      end
    end
    i = i + 1
  end
  return pts
end

-- `f() { case $1 in a) … ;; b) … ;; esac }` written on one line (or already broken by hand
-- or by an older run): join it and give every case item its own line; shfmt then indents it.
local function sh_expand_case(lines, w)
  local out, i = {}, 1
  while i <= #lines do
    local l = lines[i]
    local head = l:match("^(%s*[%w_%-]+%(%)%s*{)%s+case%s")
    if head then
      local j, k = l, i
      while not j:match("esac%s*;?%s*}%s*$") and k < #lines and k - i < 40 do
        k = k + 1
        j = j .. " " .. lines[k]:gsub("^%s+", "")
      end
      local body = j:match("^%s*[%w_%-]+%(%)%s*{%s+(case%s.-esac)%s*;?%s*}%s*$")
      if body and vim.fn.strdisplaywidth(l) > w or (body and k > i) then
        local word, items = body:match("^(case%s.-%sin)%s+(.*)%s+esac$")
        if word then
          out[#out + 1] = head
          out[#out + 1] = word
          local from = 1
          for _, pt in ipairs(sh_splits(items)) do
            if pt[2] == 3 and items:sub(pt[1] - 1, pt[1]) == ";;" then
              out[#out + 1] = items:sub(from, pt[1])
              from = pt[1] + 2
            end
          end
          if from <= #items then out[#out + 1] = items:sub(from) end
          out[#out + 1] = "esac"
          out[#out + 1] = "}"
          i = k + 1
          goto continue
        end
      end
    end
    -- `f() { cmd; }` that does not fit: body on its own line, so it can be wrapped
    local fhead = l:match("^(%s*[%w_%-]+%(%)%s*{)%s+%S")
    if fhead and not l:match("^%s*#") then
      local j, k = l, i
      while j:match("\\%s*$") and k < #lines and k - i < 20 do
        k = k + 1
        j = j:gsub("\\%s*$", "") .. " " .. lines[k]:gsub("^%s+", "")
      end
      local inner = j:match("^%s*[%w_%-]+%(%)%s*{%s+(.-)%s*;?%s*}%s*$")
      if inner and not inner:gsub("'[^']*'", ""):gsub('"[^"]*"', ""):find("[{}]") and vim.fn.strdisplaywidth(j) > w then
        out[#out + 1] = fhead
        out[#out + 1] = inner
        out[#out + 1] = "}"
        i = k + 1
        goto continue
      end
    end
    out[#out + 1] = l
    i = i + 1
    ::continue::
  end
  return out
end

local function wrap_shell(first, last)
  if not vim.bo.filetype:match("^b?a?sh$") and vim.bo.filetype ~= "zsh" then return end
  local w, sw = sh_width(), vim.fn.shiftwidth()
  local lines = sh_expand_case(vim.api.nvim_buf_get_lines(0, first - 1, last, false), w)
  local out, heredoc = {}, nil
  for _, l in ipairs(lines) do
    if heredoc then
      out[#out + 1] = l
      if l:match("^%s*(.-)%s*$") == heredoc then heredoc = nil end
    else
      local tag = l:match("<<%-?%s*['\"]?([%w_]+)")
      if tag and not l:match("<<<") then heredoc = tag end
      local indent = l:match("^%s*")
      local rest = l
      local guard = 0
      while not heredoc and not rest:match("^%s*#") and guard < 20
        and vim.fn.strdisplaywidth(rest) > w do
        guard = guard + 1
        local at, prio
        for _, pt in ipairs(sh_splits(rest)) do
          if pt[1] + 2 <= w and pt[1] > #indent + 8 and (not prio or pt[2] >= prio) then
            at, prio = pt[1], pt[2]
          end
        end
        if not at then break end
        out[#out + 1] = rest:sub(1, at) .. (prio == 3 and "" or " \\")
        indent = indent .. string.rep(" ", sw) -- hanging indent (shfmt fixes it later)
        rest = indent .. rest:sub(at + 2)
      end
      out[#out + 1] = rest
    end
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, out)
end

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
    if done and vim.bo.filetype:match("sh$") then
      wrap_shell(1, vim.api.nvim_buf_line_count(0))
      conform.format({ async = false, timeout_ms = 5000, lsp_format = "fallback" }) -- re-indent the new lines
    end
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
  vim.api.nvim_create_user_command("CleanTrim", M.trim_all, { desc = "Trim trailing whitespace (whole file)" })
  vim.api.nvim_create_user_command("FormatAll", M.format_all, { desc = "Format the whole file (formatter, wrap at 80)" })
  local map = vim.keymap.set
  map("n", "<leader>cw", "<cmd>CleanTrim<cr>", { desc = "Trim trailing whitespace" })
  map("n", "<leader>uW", function()
    vim.g.clean_on_save = not vim.g.clean_on_save
    vim.notify("Clean changed lines on save: " .. (vim.g.clean_on_save and "on" or "off"))
  end, { desc = "Toggle clean-on-save" })
end

return M
