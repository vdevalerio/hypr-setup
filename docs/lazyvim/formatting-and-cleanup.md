# Formatting and cleanup

Everything is wrapped at **column 80**. A ruler (`colorcolumn = 80`) is always
visible and tinted with the theme's mauve accent.

## What happens on save

Autoformat on save is **off** (`vim.g.autoformat = false`). Instead
`lua/config/cleanup.lua` runs on every write, **only on the lines changed since
the last write** (compared with the file on disk, no git needed):

1. trailing whitespace is trimmed (Markdown keeps two-space line breaks);
2. the changed lines are re-indented / re-wrapped through the formatter when it
   supports ranges (ruff, prettier, stylua), otherwise with `=`;
3. Python: full-line `#` comments longer than 80 columns are hard-wrapped with
   `gq` (ruff never rewraps comments; shebangs, `# %%` cells and `# noqa` /
   `# type:` pragmas are skipped; trailing comments after code are left alone);
4. Python: docstrings (a string that is a whole statement) with a line over 80
   columns have that paragraph re-filled to 80. Paragraphs laid out in columns
   (runs of spaces inside a line) are only broken at the long line, with a
   4-space hanging indent, never joined. Other triple-quoted strings (SQL, …)
   are untouched.

Prose filetypes (markdown, text, help, diff, gitcommit) are never re-indented.

## On demand

| Keys | Command | Action |
| --- | --- | --- |
| `<leader>cf` | `:FormatAll` | Format the **whole file**: trim, formatter, wrap at 80 (shell: also breaks long lines); no formatter → re-indent with `=` |
| `<leader>cf` (visual) | | Format only the **selection** (LazyVim's mapping) |
| `<leader>cw` | `:CleanTrim` | Only trim trailing whitespace (file) |
| `<leader>uW` | | Toggle clean-on-save |
| `gq{motion}` | | Hard-wrap prose (e.g. `gqap` in Markdown) |
| `=` / `gg=G` | | Re-indent with Neovim's own rules |

Indentation width and line width are never typed in a command: they come from
the project's `.editorconfig` (below).

## Formatter settings

`lua/plugins/formatting.lua` (conform.nvim):

- `ruff_format --line-length 80` for Python;
- `prettier --prose-wrap always --print-width 80` for Markdown and web files;
- `stylua --column-width 80` for Lua.

`markdownlint-cli2` uses the config in `~/.config/markdownlint`.

## Indentation and line width per project

Put an `.editorconfig` at the root of a project (this repo has one):

```ini
root = true

[*]
indent_style = space
indent_size = 4
max_line_length = 80

[*.{lua,md,json,yml}]
indent_size = 2
```

Neovim applies it to every buffer (`shiftwidth`, `textwidth`), and shfmt,
prettier and stylua read it too, so `<leader>cf` and re-indenting follow it.
Without an `.editorconfig` the default is 2 spaces and 80 columns. Change the
number in the file to change the width for that project or file type; reopen the
buffer (or `:e`) to apply it.

## Shell scripts

`<leader>cf` runs shfmt (indentation from `.editorconfig`), then breaks every
line wider than `max_line_length` with a trailing `\`: after `;` / `;;` (new
line, no `\`), else after `&&`, `||` or `|`, else between two words, also
inside `$( … )`. Quoted strings, `${ }`, `$(( ))`, heredocs and comments are not
split (long full-line comments are re-wrapped; a comment laid out in columns,
like a usage table, wraps with a hanging indent under its description). shfmt then re-indents the new lines. Function one-liners that do not fit are expanded first: `f() { case … esac }`
becomes a `case` with one item per line, and `f() { long command; }` puts its
body on its own line (shfmt keeps hand-broken one-liners as they are, with the
continuation lines at column 0, so they are joined and rebuilt). An `awk '…'` program is also broken after `;` or `}` (awk accepts a newline
there). Any other long quoted string stays on one line. Line-continuation `\` does not change what the script does.

## Hard wrapping text

Plain text (`filetype=text`) is hard-wrapped by `:FormatAll` (`<leader>cf`). In Markdown use
`gq{motion}` (e.g. `gqap`) for a paragraph.
