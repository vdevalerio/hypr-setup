# Lazygit

Terminal UI for git. Run `lg` in a repo, or `<leader>gg` inside Neovim. Config:
`~/.config/lazygit/config.yml` (rounded borders, `delta` for diffs, colors from the
terminal theme). `?` shows the keys for the current panel; `q` quits.

## Panels

`1` Status · `2` Files · `3` Branches · `4` Commits · `5` Stash.
`Tab` / `←` `→` switch panels, `j` `k` move, `Enter` drills in, `Esc` goes back.

## Files

| Keys | Action |
| --- | --- |
| `Space` | Stage / unstage the file |
| `a` | Stage / unstage all |
| `c` | Commit |
| `A` | Amend the last commit |
| `d` | Discard changes |
| `e` | Edit the file (in `$EDITOR`) |
| `i` | Add to `.gitignore` |
| `s` | Stash changes |
| `Enter` | Stage individual lines/hunks (`Space` per line, `a` for a hunk) |

## Branches and commits

| Keys | Action |
| --- | --- |
| `Space` | Check out the branch / commit |
| `n` | New branch |
| `M` | Merge the branch into the current one |
| `r` | Rebase onto the branch |
| `d` | Delete branch |
| `R` | Rename branch |
| `P` | Push |
| `p` | Pull |
| `f` | Fetch |
| `s` / `r` / `d` (on a commit) | Squash / reword / drop |
| `e` | Edit a commit during an interactive rebase |
| `C` / `V` | Cherry-pick copy / paste |
| `g` | Reset menu |
| `z` | Undo (reflog) |
| `/` | Filter |
