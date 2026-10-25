-- Formatters wrap code at column 80 (the ruler). Python goes through ruff directly instead of the
-- ruff LSP so the width is set here; conform's range support is what lets cleanup.lua
-- reformat only the changed lines.
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { python = { "ruff_format" } },
      formatters = {
        ruff_format = { append_args = { "--line-length", "80" } },
        stylua = { prepend_args = { "--column-width", "80" } },
      },
    },
  },
}
