-- Diagnostics: show the whole message under the cursor line (wrapped onto
-- extra lines) instead of inline virtual text that gets cut at the window edge.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        virtual_lines = { current_line = true },
      },
    },
  },
}
