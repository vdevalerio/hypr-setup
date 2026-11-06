# Yazi

Terminal file manager. Open it with `SUPER + E`, `Ctrl+Y` in the shell, or
`y` (changes the shell directory on exit). `F1` or `~` shows every key inside it.

Layout: parents · current folder · preview (1:3:4). Natural sort, directories
first, mouse enabled. Image/PDF/video previews use `poppler`, `ffmpegthumbnailer`
and `resvg`.

## Navigation

| Keys | Action |
| --- | --- |
| `h` / `l` | Parent directory / enter or open |
| `j` / `k` | Down / up |
| `gg` / `G` | Top / bottom |
| `H` / `L` | History back / forward |
| `z` | Jump with fzf |
| `Z` | Jump with zoxide |
| `/` `?` | Search forward / backward; `n` `N` next / previous |
| `f` | Filter the current folder |
| `.` | Toggle hidden files |
| `~` / `F1` | Help |
| `q` | Quit; `Ctrl+Y` quits and `cd`s the shell |

## Selection and file operations

| Keys | Action |
| --- | --- |
| `Space` | Toggle selection (moves down) |
| `v` / `V` | Visual mode |
| `Ctrl+a` | Select all |
| `y` / `x` | Yank (copy) / cut |
| `p` / `P` | Paste / paste, overwriting |
| `d` | Trash |
| `D` | Delete permanently |
| `a` | Create (end with `/` for a directory) |
| `r` | Rename |
| `;` / `:` | Run a shell command |
| `o` / `Enter` | Open |
| `O` | Open with… |
| `Tab` | File info |
| `Ctrl+s` | Cancel a running search |

## Tabs

`t` new tab, `1…9` switch, `[` / `]` previous / next, `{` / `}` move the tab,
`Ctrl+c` close the tab.

## Sorting and copying paths

`,` opens the sort menu (`m` modified, `s` size, `n` name, `e` extension).
`c` then `c` copies the path, `c f` the file name, `c d` the directory.

## Config

`~/.config/yazi/yazi.toml` (layout, hidden files), `keymap.toml` (the extra
`Ctrl+Y`), `theme.toml`. Colors follow the terminal's ANSI palette.
