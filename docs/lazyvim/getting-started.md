# Getting started

## Modes

| Mode | Enter with | Purpose |
| --- | --- | --- |
| Normal | `Esc` (or `jk`-less: just `Esc`) | Move around, run commands |
| Insert | `i`, `a`, `o`, `O`, `I`, `A` | Type text |
| Visual | `v` (chars), `V` (lines), `Ctrl+v` (block) | Select text |
| Command | `:` | Ex commands (`:w`, `:q`, `:Lazy`) |

## Motions you will use daily

| Keys | Moves to |
| --- | --- |
| `h j k l` | Left, down, up, right |
| `w` / `b` / `e` | Next word start / previous word start / word end |
| `0` / `^` / `$` | Line start / first non-blank / line end |
| `gg` / `G` | File start / end |
| `{` / `}` | Previous / next paragraph |
| `%` | Matching bracket |
| `Ctrl+d` / `Ctrl+u` | Half page down / up |
| `s` + 2 chars | **flash.nvim** jump to any visible match |
| `]]` / `[[` | Next / previous reference of the word under the cursor |

## Operators

Operators combine with motions: `d` delete, `c` change, `y` yank (copy), `>`/`<`
indent, `gc` comment.

`dw` delete a word · `ciw` change the word under the cursor · `yy` copy a line ·
`dap` delete a paragraph · `gcc` comment a line · `gc` in visual mode comments
the selection. `.` repeats the last change, `u` undoes, `Ctrl+r` redoes.

## Files and quitting

| Keys / command | Action |
| --- | --- |
| `:w` or `Ctrl+s` | Save |
| `<leader>qq` | Quit everything |
| `:q` / `:q!` | Close window / discard changes |
| `<leader>fn` | New file |

## When something is unknown

- `<leader>` then wait: which-key lists the next keys.
- `<leader>sk` searches keymaps, `<leader>sh` the help pages, `<leader>:`
  the command history.
- `:checkhealth` diagnoses missing tools.
