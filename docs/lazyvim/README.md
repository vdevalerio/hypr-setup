# LazyVim (Neovim)

Neovim 0.11+ with the [LazyVim](https://www.lazyvim.org) distribution, tuned for
Python and data work. The config lives in `~/.config/nvim` (repo:
`dotfiles/.config/nvim`).

`<leader>` is `Space`. Press it and wait: **which-key** pops up with every
follow-up key. `<leader>sk` searches all keymaps by name.

| Guide | What it covers |
| --- | --- |
| [Getting started](getting-started.md) | Modes, motions, the leader key, survival basics |
| [File explorer](file-explorer.md) | Snacks explorer, dotfile toggle, file operations |
| [Buffers and windows](buffers-and-windows.md) | Tabs-like buffers, splits, tmux interplay |
| [Searching](searching.md) | Files, grep, symbols, `/` search, flash jumps |
| [Code intelligence](code-intelligence.md) | LSP, completion, diagnostics, Mason |
| [Git](git.md) | gitsigns, lazygit, diffs |
| [Formatting and cleanup](formatting-and-cleanup.md) | Column 80, clean-on-save, `<leader>c*` |
| [Python and data](python-and-data.md) | IPython REPL, `# %%` cells, notebooks, CSV view |
| [Writing](writing.md) | Markdown, spell checking (EN + PT-BR), man pages |
| [Configuration](configuration.md) | How the config is laid out and how to change it |

## Cheat sheet

| Keys | Action |
| --- | --- |
| `<leader>e` | File explorer (toggle) |
| `<leader><space>` | Find files |
| `<leader>/` | Grep in the project |
| `<leader>,` | Switch buffer |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `<leader>bd` | Close buffer |
| `<C-h/j/k/l>` | Move between windows |
| `gd` / `gr` / `K` | Definition / references / hover |
| `<leader>ca` | Code action |
| `<leader>cf` | Format file |
| `<leader>gg` | Lazygit |
| `<leader>uH` | Toggle dotfiles in the explorer |
| `<leader>l` | Lazy (plugin manager) |
| `<leader>cm` | Mason (LSP/formatter installer) |
| `<leader>qq` | Quit all |
