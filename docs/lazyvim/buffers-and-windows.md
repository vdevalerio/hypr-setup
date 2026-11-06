# Buffers and windows

A **buffer** is an open file, a **window** is a viewport onto a buffer. LazyVim
shows open buffers in the top bufferline instead of using Vim tabs.

## Buffers

| Keys | Action |
| --- | --- |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `[b` / `]b` | Previous / next buffer (alternative) |
| `<leader>,` or `<leader>fb` | Pick a buffer from a list |
| `<leader>bb` or `` <leader>` `` | Switch to the alternate (last) buffer |
| `<leader>bd` | Delete (close) the buffer, keep the window |
| `<leader>bD` | Delete the buffer and window |
| `<leader>bo` | Close all other buffers |
| `<leader>bp` | Pin buffer |
| `<leader>bP` | Delete non-pinned buffers |
| `<leader>br` / `<leader>bl` | Delete buffers to the right / left |
| `:e file` | Open a file in the current window |

## Windows (splits)

| Keys | Action |
| --- | --- |
| `<leader>-` | Split below |
| `<leader>\|` | Split to the right |
| `<leader>wd` | Close the window |
| `<C-h/j/k/l>` | Move focus between windows |
| `<C-Up/Down/Left/Right>` | Resize the window |
| `<leader>wm` | Maximize / restore the window (zoom) |
| `<leader>ww` | Jump to the other window |
| `<C-w>=` | Equalize sizes |

## Tabs (rarely needed)

`<leader><tab><tab>` creates a tab page, `<leader><tab>]` / `[` switch,
`<leader><tab>d` closes. Prefer buffers.

## Terminal

`<C-/>` opens a floating terminal; press it again to hide. `<leader>ft` opens a
terminal at the project root.

## With tmux and the compositor

`<C-h/j/k/l>` is Neovim's window navigation. tmux pane navigation uses its prefix
(`Ctrl+a` then `h/j/k/l`, see [tmux](../tmux/README.md)), and Hyprland uses
`SUPER+h/j/k/l`, so the three layers do not collide.
