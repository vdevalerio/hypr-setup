# Python and data work

All of this lives in `lua/plugins/datascience.lua`.

## Cells and the IPython REPL

Write Jupyter-style cells in a `.py` file, separated by `# %%` (highlighted as
a full line). The REPL is IPython from the project `.venv` (falls back to the
global one) opening in a right-hand split.

| Keys | Action |
| --- | --- |
| `<S-CR>` | Run the current cell and move to the next |
| `<leader>jr` | Toggle the REPL |
| `<leader>jR` | Restart the REPL |
| `<leader>jc` | Run the cell |
| `<leader>jn` | Run the cell and move to the next |
| `<leader>jl` | Run the current line |
| `<leader>js` (visual) | Run the selection |
| `<leader>jf` | Run the whole file |
| `<leader>ju` | Run everything up to the cursor |
| `<leader>ji` | Interrupt (`Ctrl+C`) |
| `<leader>jq` | Close the REPL |
| `<leader>jx` | Clear the REPL |
| `]j` / `[j` | Next / previous cell |
| `<leader>ja` | Add a cell below |

## Notebooks

`.ipynb` files open as `.py` with `# %%` cells (jupytext, `py:percent` format)
and are saved back to `.ipynb`, keeping existing outputs.

## CSV / TSV

Files open as an aligned table with `│` borders, one color per column and a bold
header. The header stays on top (with a `━` line) and the **first column stays
in place** while you scroll sideways, like frozen panes in a spreadsheet. The
ruler and relative numbers are off in these buffers and the current row is
highlighted.

| Keys | Action |
| --- | --- |
| `Tab` / `Shift+Tab` | Next / previous field |
| `if` / `af` | Field text objects (`dif`, `yaf`…) |
| `<leader>uv` | Toggle the table view (raw text) |
| `<leader>uV` | Open the file in **csvlens**, full screen: `/` search, `f` filter columns, sort, `q` back |

Comments starting with `#` or `//` are ignored. Change the look in
`lua/plugins/datascience.lua` (`view = { spacing, min_column_width,
sticky_columns = { count = 1 } … }`).

## Project setup

```sh
mkds my-analysis    # uv project + pandas numpy scikit-learn matplotlib seaborn polars pyarrow ipykernel (+ ipython ruff pytest)
```

`cd` into the project and the `.venv` activates by itself (see
[zsh](../zsh/README.md)). Neovim picks it up for the LSP and the REPL; use
`<leader>cv` (venv-selector) to switch manually.

## Type checking

`basedpyright` runs in `standard` mode on open files only, so pandas/numpy code
is not flooded with warnings. Ruff handles lint and formatting.
