# Shell: zsh and friends

Config: `~/.zshrc`. Prompt: [starship](https://starship.rs) (`~/.config/starship.toml`).

## Editing the command line

Emacs keys (`bindkey -e`): `Ctrl+a/e` start/end, `Ctrl+w` delete word, `Ctrl+k`
delete to end, `Ctrl+u` delete to start, `Ctrl+←/→` word jumps, `Ctrl+Backspace`
delete word back.

| Feature | How |
| --- | --- |
| Autosuggestions (gray text) | `→` or `End` accepts it |
| History search by prefix | type a prefix and press `↑`/`↓` |
| Fuzzy history | `Ctrl+R` ([atuin](../tools/README.md)) |
| Fuzzy file picker | `Ctrl+T` (fzf, with a bat preview) |
| Fuzzy directory jump | `Alt+C` (fzf, with a tree preview) |
| Smart `cd` | `z part-of-name` (zoxide) |
| File manager | `Ctrl+Y` opens yazi; leaving it `cd`s the shell |
| Completion menu | `Tab`, `Shift+Tab` goes backwards |

`autocd` is on: typing a directory name enters it. Hidden files match globs
(`glob_dots`).

## Aliases and functions

| Name | Does |
| --- | --- |
| `ls` / `ll` / `la` / `lt` | `lsd` plain / long with git / all / tree depth 2 |
| `cat` | `bat` (plain, no pager) |
| `v`, `vim` | `nvim` |
| `lg` | lazygit |
| `help cmd` | `tldr cmd` short examples |
| `..`, `...` | Go up one / two directories |
| `update` | Safe system update (Arch news first) |
| `backup` | restic backup to Google Drive |
| `py`, `ipy` | python, ipython |
| `ccu` | Claude Code token usage report |
| `mkds name` | New uv data-science project (pandas, numpy, sklearn, matplotlib, seaborn, polars, pyarrow, ipykernel + ipython, ruff, pytest) |
| `y` | yazi that changes directory on exit |

## Python environments

Entering a directory that has (or sits under one with) `.venv` activates it;
leaving deactivates it. `mise` manages language runtimes, `direnv` loads `.envrc`
files, `uv` creates projects and installs tools.

## History

`~/.local/state/zsh/history`, 50 000 entries, shared between sessions, duplicates
removed. Atuin keeps its own searchable database and filters out commands that
export tokens or secrets.
