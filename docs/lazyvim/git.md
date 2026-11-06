# Git inside Neovim

## Lazygit

`<leader>gg` opens [lazygit](../lazygit/README.md) in a floating window at the
project root; `<leader>gG` uses the current directory. Quit with `q`.

## Gutter signs (gitsigns)

Signs appear in the left column for added, changed and removed lines. Hunks are
not tracked in converted `.ipynb` buffers (disabled on purpose).

| Keys | Action |
| --- | --- |
| `]h` / `[h` | Next / previous hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghS` / `<leader>ghR` | Stage / reset the whole buffer |
| `<leader>ghu` | Undo stage hunk |
| `<leader>ghp` | Preview hunk inline |
| `<leader>ghb` | Blame line (full) |
| `<leader>ghB` | Blame buffer |
| `<leader>ghd` | Diff against the index |
| `<leader>ghD` | Diff against the last commit |
| `ih` (operator-pending) | Select the hunk as a text object |

## Browsing history

| Keys | Action |
| --- | --- |
| `<leader>gl` | Git log |
| `<leader>gL` | Git log (cwd) |
| `<leader>gb` | Git log of the current line (blame) |
| `<leader>gf` | History of the current file |
| `<leader>gB` | Open the file on GitHub (browse) |
| `<leader>gs` | Git status picker |
| `<leader>gd` | Git diff (hunks) picker |
