-- Formatters wrap code and prose (prettier, markdown) at column 80 (the ruler). Python goes through ruff directly instead of the
-- ruff LSP so the width is set here; conform's range support is what lets cleanup.lua
-- reformat only the changed lines.
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { python = { "ruff_format" } },
      formatters = {
        ruff_format = { append_args = { "--line-length", "80" } },
        prettier = { prepend_args = { "--prose-wrap", "always", "--print-width", "80" } },
        stylua = { prepend_args = { "--column-width", "80" } },
      },
    },
  },
  {
    -- Fixed config path: with stdin, markdownlint-cli2 only looks for configs in the cwd
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = { args = { "--config", vim.fn.expand("~/.config/markdownlint/config.jsonc"), "-" } },
      },
    },
  },
}
