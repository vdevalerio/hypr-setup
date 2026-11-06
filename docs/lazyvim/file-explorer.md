# File explorer

LazyVim's default explorer is the **Snacks explorer** (a picker docked on the
left). There is no neo-tree in this setup (`lazyvim.json` has no extras).

## Opening it

| Keys | Action |
| --- | --- |
| `<leader>e` | Toggle the explorer at the project root |
| `<leader>E` | Toggle the explorer at the current working directory |
| `<leader>fe` / `<leader>fE` | Same, under the *find* group |

## Toggling dotfiles

Hidden files (`.git`, `.zshrc`, `.env`) can be shown or hidden:

| Keys | Where | Action |
| --- | --- | --- |
| `H` | Inside the explorer | Toggle hidden files |
| `I` | Inside the explorer | Toggle git-ignored files |
| `<leader>uH` | Anywhere | Toggle hidden files in the open explorer; with no explorer open, opens one with dotfiles visible |

`<leader>uH` is defined in `lua/plugins/explorer.lua`. The `<leader>u` group is
the UI-toggle group (`<leader>uw` wrap, `<leader>us` spell, `<leader>uv` CSV
view...).

## Navigating inside the explorer

| Keys | Action |
| --- | --- |
| `j` / `k` | Down / up |
| `l` / `Enter` | Open file or expand directory |
| `h` | Collapse directory (or go to parent) |
| `<BS>` | Go up one directory |
| `.` | Focus (zoom into) the directory under the cursor |
| `Z` | Collapse every directory |
| `P` | Toggle the preview |
| `u` | Refresh the tree |
| `]g` / `[g` | Next / previous git-modified file |
| `]d` / `[d`, `]e` / `[e` | Next / previous diagnostic / error |
| `<C-t>` | Open a terminal in the directory |
| `<leader>/` | Grep inside the directory under the cursor |

## File operations

| Keys | Action |
| --- | --- |
| `a` | Add a file; end the name with `/` to create a directory |
| `r` | Rename |
| `d` | Delete |
| `c` | Copy the file (then `p` to paste it elsewhere) |
| `m` | Move the file (then `p` to paste it elsewhere) |
| `y` | Yank (mark) files, also in visual mode; `p` pastes them |
| `o` | Open with the system opener (`xdg-open`) |

Press `?` inside the explorer for the full list of bindings in your version.

## Tips

- Close the explorer with `q` or `<leader>e` again.
- The explorer follows the current buffer; use `<leader>fe` to jump to it.
- For heavy file management, use [Yazi](../yazi/README.md) (`SUPER+E`, or
  `Ctrl+Y` in the shell).
