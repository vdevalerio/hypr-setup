-- Python / data mining: IPython REPL with cells "# %%" (Jupyter style),
-- .ipynb notebooks opened as .py, CSV as a table and plots in a floating window.
--
-- Workflow: write cells separated by "# %%" in a .py and use
--   <S-CR>      runs the current cell and moves to the next (like Jupyter)
--   <leader>jr  opens/closes the REPL (IPython from the project .venv)
--   ]j / [j     next / previous cell         <leader>ja  new cell below

local function python_repl()
  -- Prefers the IPython from the active venv (venv-selector or project .venv)
  local venv = vim.env.VIRTUAL_ENV
  if not venv then
    local found = vim.fs.find(".venv", { upward = true, type = "directory", path = vim.fn.expand("%:p:h") })[1]
    venv = found
  end
  if venv and vim.fn.executable(venv .. "/bin/ipython") == 1 then
    return { venv .. "/bin/ipython", "--no-autoindent" }
  end
  return { "ipython", "--no-autoindent" }
end

local cell_pattern = [[^\s*#\s*%%]]

local function goto_cell(flags)
  if vim.fn.search(cell_pattern, flags .. "W") == 0 then
    vim.notify("No more cells", vim.log.levels.INFO)
  end
end

return {
  -- Interactive REPL (IPython) receiving cells, lines or selections
  {
    "Vigemus/iron.nvim",
    ft = { "python" },
    cmd = { "IronRepl", "IronRestart", "IronFocus", "IronHide" },
    config = function()
      local view = require("iron.view")
      local common = require("iron.fts.common")
      require("iron.core").setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            python = {
              command = python_repl,
              format = common.bracketed_paste,
              block_dividers = { "# %%", "#%%" },
            },
          },
          repl_open_cmd = view.split.vertical.rightbelow("%40"),
          dap_integration = true,
        },
        keymaps = {
          toggle_repl = "<leader>jr",
          restart_repl = "<leader>jR",
          send_code_block = "<leader>jc",
          send_code_block_and_move = "<leader>jn",
          send_line = "<leader>jl",
          visual_send = "<leader>js",
          send_file = "<leader>jf",
          send_until_cursor = "<leader>ju",
          interrupt = "<leader>ji",
          exit = "<leader>jq",
          clear = "<leader>jx",
        },
        highlight = { italic = true },
        ignore_blank_lines = true,
      })
    end,
    keys = {
      { "<S-CR>", function() require("iron.core").send_code_block(true) end, ft = "python", desc = "Run cell and go to next" },
      { "<leader>jr", desc = "Toggle REPL (IPython)" },
      { "<leader>jR", desc = "Restart REPL" },
      { "<leader>jc", desc = "Run cell" },
      { "<leader>jn", desc = "Run cell and go to next" },
      { "<leader>jl", desc = "Run line" },
      { "<leader>js", mode = "v", desc = "Run selection" },
      { "<leader>jf", desc = "Run whole file" },
      { "<leader>ju", desc = "Run until cursor" },
      { "<leader>ji", desc = "Interrupt (Ctrl+C)" },
      { "<leader>jq", desc = "Close REPL" },
      { "<leader>jx", desc = "Clear REPL" },
      { "]j", function() goto_cell("") end, ft = "python", desc = "Next cell" },
      { "[j", function() goto_cell("b") end, ft = "python", desc = "Previous cell" },
      {
        "<leader>ja",
        function()
          local row = vim.fn.search(cell_pattern, "nW")
          row = row == 0 and vim.api.nvim_buf_line_count(0) or row - 1
          vim.api.nvim_buf_set_lines(0, row, row, false, { "", "# %%", "" })
          vim.api.nvim_win_set_cursor(0, { row + 3, 0 })
          vim.cmd.startinsert()
        end,
        ft = "python",
        desc = "Add cell below",
      },
    },
  },

  -- Group in which-key
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>j", group = "jupyter / repl", icon = { icon = " ", color = "orange" } } } },
  },

  -- Highlights the cell lines "# %%"
  {
    "nvim-mini/mini.hipatterns",
    opts = function(_, opts)
      opts.highlighters = opts.highlighters or {}
      opts.highlighters.cell = { pattern = "^%s*#%s*%%%%.*", group = "CursorLine" }
    end,
  },

  -- Notebooks .ipynb: opens as .py with "# %%" cells and saves back to .ipynb
  -- (keeping the outputs already in the notebook)
  {
    "goerz/jupytext.nvim",
    lazy = false,
    opts = { format = "py:percent", filetype = "python", update = true },
  },
  -- gitsigns is not compatible with converted .ipynb; disabled only for them
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local on_attach = opts.on_attach
      opts.on_attach = function(bufnr)
        if vim.api.nvim_buf_get_name(bufnr):match("%.ipynb$") then
          return false
        end
        if on_attach then
          return on_attach(bufnr)
        end
      end
    end,
  },

  -- CSV/TSV as an aligned table (Tab/Shift+Tab jump between columns)
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    opts = {
      parser = { comments = { "#", "//" } },
      view = { display_mode = "border", header_lnum = 1 },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
      },
    },
    config = function(_, opts)
      require("csvview").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv" },
        callback = function() vim.cmd("CsvViewEnable") end,
      })
      if vim.tbl_contains({ "csv", "tsv" }, vim.bo.filetype) then
        vim.cmd("CsvViewEnable")
      end
    end,
    keys = { { "<leader>uv", "<cmd>CsvViewToggle<cr>", desc = "Toggle CSV table view" } },
  },

  -- Python: less noisy type checking for data analysis (pandas/numpy)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                diagnosticMode = "openFilesOnly",
                autoImportCompletions = true,
                inlayHints = { callArgumentNames = true, variableTypes = false },
              },
            },
          },
        },
      },
    },
  },

  -- Extra syntax parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "python", "sql", "csv", "markdown", "markdown_inline", "toml", "yaml", "json", "rst", "requirements" },
    },
  },
}
