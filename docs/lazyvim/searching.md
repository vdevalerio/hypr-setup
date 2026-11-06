# Searching

LazyVim uses the Snacks picker (fzf-like) for everything. Inside any picker:
type to filter, `<C-j>/<C-k>` move, `Enter` opens, `<C-v>`/`<C-s>` open in a
split, `<C-q>` sends results to the quickfix list, `<A-h>` toggles hidden files,
`<A-i>` toggles ignored files, `?` lists the picker keys.

## Files

| Keys | Action |
| --- | --- |
| `<leader><space>` | Find files (project root) |
| `<leader>ff` | Find files (root) |
| `<leader>fF` | Find files (cwd) |
| `<leader>fr` | Recent files |
| `<leader>fb` | Buffers |
| `<leader>fg` | Files tracked by git |
| `<leader>fc` | Config files |

## Text

| Keys | Action |
| --- | --- |
| `<leader>/` | Grep in the project (ripgrep) |
| `<leader>sg` | Grep (root) |
| `<leader>sw` | Grep the word under the cursor |
| `<leader>sb` | Search lines in the current buffer |
| `<leader>sr` | Search and replace (grug-far) |
| `<leader>sk` | Search keymaps |
| `<leader>sh` | Search help |
| `<leader>sd` | Search diagnostics |
| `<leader>ss` | Search symbols in the file (LSP) |
| `<leader>sS` | Search symbols in the workspace |
| `<leader>sc` | Command history |

## In-buffer search

| Keys | Action |
| --- | --- |
| `/` `?` | Search forward / backward |
| `n` / `N` | Next / previous match |
| `*` / `#` | Search the word under the cursor |
| `Esc` | Clear highlights |
| `s` + 2 chars | Flash: jump to any visible spot |
| `S` | Flash Treesitter: select a syntax node |

## Command line equivalents

The same tools are available in the shell: `fd`, `rg`, `fzf` (`Ctrl+T`,
`Alt+C`), see [zsh](../zsh/README.md).
