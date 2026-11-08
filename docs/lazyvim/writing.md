# Writing

## Spell checking

Languages: English and Brazilian Portuguese (`spelllang = en, pt_br`). Toggle
with `<leader>us`.

| Keys | Action |
| --- | --- |
| `]s` / `[s` | Next / previous misspelling |
| `z=` | Suggestions for the word |
| `zg` | Add the word to the **English** list |
| `2zg` | Add to the **Portuguese** list |
| `3zg` | Add to the **tech** list (technical terms) |
| `zw` | Mark as wrong |
| `zug` | Undo adding |

The word lists are plain text in `~/.config/nvim/spell/*.add`, versioned with
the repo. The compiled `.spl` files are rebuilt automatically and git-ignored.

## Markdown

- `marksman` provides links/outline; `markdownlint-cli2` lints.
- `prettier` formats and wraps at 80.
- `<leader>cp` toggles the in-editor markdown preview (render-markdown).
- `render-markdown.nvim` renders headings, tables and code blocks inline;
  `<leader>um` toggles it. Tables stay rendered while you move the cursor in
  normal mode (anti-conceal is off, `plugins/markdown.lua`); insert mode shows
  the real characters for editing. Cells wider than the window wrap onto
  several lines, also on the cursor line. `markdown-toc` can generate a table of contents.
- **Mermaid:** a ` ```mermaid ` block is drawn as a diagram right below its code
  (`plugins/mermaid.lua`: Snacks.image + `mmdc`, kitty graphics protocol, also inside
  tmux). Diagrams are cached and re-rendered only when the block changes;
  `<leader>uI` shows the image under the cursor in a float. Needs `mmdc`
  (`./install.sh nvim` installs it).

## Man pages

`MANPAGER` is `nvim +Man!`: `man ls` opens in Neovim, with `gO` for the outline
and `K` to follow references.
