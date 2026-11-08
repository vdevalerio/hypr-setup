# Code intelligence

## Language servers (LSP)

Installed by Mason, configured by LazyVim:

| Language | Server / tools |
| --- | --- |
| Python | `basedpyright` (types, `standard` mode, open files only), `ruff` (lint + format) |
| Lua | `lua-language-server`, `stylua` |
| JSON / YAML / TOML | `json-lsp`, `yaml-language-server`, `taplo` |
| Markdown | `marksman`, `markdownlint-cli2`, `prettier` |
| Docker | `dockerfile-language-server`, `docker-compose-language-service`, `hadolint` |
| SQL | `sqlfluff` |
| Shell | `shfmt` |

Python options live in `lua/config/options.lua` (`lazyvim_python_lsp`,
`lazyvim_python_ruff`) and `lua/plugins/datascience.lua`.

## Navigation

| Keys | Action |
| --- | --- |
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Implementation |
| `gy` | Type definition |
| `gD` | Declaration |
| `K` | Hover documentation |
| `gK` | Signature help |
| `<C-o>` / `<C-i>` | Jump back / forward |

## Editing

| Keys | Action |
| --- | --- |
| `<leader>ca` | Code actions (quick fixes, imports) |
| `<leader>cr` | Rename symbol |
| `<leader>cA` | Source actions |
| `<leader>cf` | Format file |
| `<leader>cd` | Line diagnostics |
| `]d` / `[d` | Next / previous diagnostic |
| `]e` / `[e` | Next / previous error |
| `<leader>xx` | Diagnostics list (Trouble) |
| `<leader>xX` | Buffer diagnostics |
| `<leader>cs` | Symbols outline (toggle) |
| `<leader>cl` | LSP info |

## Completion

`blink.cmp`: suggestions appear as you type. `Tab`/`Enter` accept, `<C-n>`/`<C-p>`
move, `<C-space>` opens docs/forces completion, `<C-e>` dismisses.

## Mason

`<leader>cm` opens Mason: install (`i`), uninstall (`X`), update (`U`). The set
installed by `install.sh` is `MASON_PKGS` in the repo. Treesitter parsers:
`:TSInstall <lang>`, list in `TS_PARSERS`.

## Go

The LazyVim `lang.go` extra (`lazyvim.json`) gives `gopls` (completion, diagnostics, inlay
hints, go to definition), formatting on save with `goimports` + `gofumpt` (adds/removes
imports, tabs as `gofmt` wants: `.editorconfig` has `indent_style = tab` for `*.go`),
`gomodifytags` / `impl`, Delve debugging (`<leader>d`, `nvim-dap-go`) and tests with
`neotest-golang` (`<leader>t`: run nearest, file, debug test). Tree-sitter parsers `go`,
`gomod`, `gowork`, `gosum`. Everything is installed by `./install.sh nvim` (needs `go`).

## Debugging

`debugpy` is installed through Mason for the Python adapter. The debugger keys
live under `<leader>d` (press it and read which-key); the `iron.nvim` REPL is
wired to DAP (`dap_integration`). The full UI comes from the DAP extra
(`:LazyExtras`).
