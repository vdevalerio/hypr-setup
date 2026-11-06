# Command-line tools

| Tool | Use |
| --- | --- |
| **fzf** | `Ctrl+T` files, `Alt+C` directories, `**<Tab>` completion |
| **atuin** | `Ctrl+R` searchable history with context; `↑` stays zsh's prefix search |
| **zoxide** | `z foo` jumps to the best match; `zi` interactive |
| **bat** | `cat` with syntax highlighting (aliased) |
| **lsd** / **eza** | Modern `ls` |
| **fd** / **ripgrep** | Fast `find` / `grep` (`fd name`, `rg text`) |
| **delta** | Pretty git diffs (also inside lazygit) |
| **tldr** (`help`) | Short command examples |
| **direnv** | Per-directory environment from `.envrc` (`direnv allow`) |
| **mise** | Language runtime manager (`mise use node@22`) |
| **uv** | Python projects and tools (`uv init`, `uv add`, `uv tool install`) |
| **btop** | System monitor (`btop`; opens from the bar's monitor island) |
| **fastfetch** | System summary on terminal start |
| **plocate** | `locate name` (update with `sudo updatedb`) |
| **gh** | GitHub CLI (`gh repo create`, `gh pr create`) |
| **restic + rclone** | Encrypted backups (see `backup`) |
| **todo** | Daily to-do list (`todo add "text"`, `todo`, `todo done 2`); see [todo](../todo/README.md) |
| **KeePassXC** | Password manager |
| **Brave / Firefox** | Browsers (`SUPER + B` opens Brave) |

## Atuin

`Ctrl+R` opens the search UI (compact style, global filter, fuzzy). Commands that
export tokens/keys/secrets are not saved. `atuin stats` shows usage.

## Data profile (optional, `./install.sh data`)

DBeaver, PostgreSQL client tools, `pgcli`, `mycli`, `harlequin` (terminal SQL
IDE), `lazysql`, `usql`, DuckDB, LibreOffice and Docker, plus the tools below that
make the terminal output readable. Settings live in `~/.docker/config.json`
(table formats only), `~/.config/pgcli/config`, `~/.myclirc`, `~/.psqlrc` and
`~/.config/lazydocker/config.yml`; the first four are in the repo, so
`./install.sh save` keeps them.

### Docker

| Command | What it does |
| --- | --- |
| `docker ps`, `docker images` | Short tables: name, image, status, ports / repo, tag, size, age |
| `lzd` (lazydocker) | Whole Docker in one screen. `[`/`]` switch panels, `Enter` focuses, `d` remove, `s` stop, `r` restart, `l` logs, `E` shell, `x` menu of actions, `?` help |
| `dive <image>` | Layer by layer: what each one adds. `Tab` switches layer/file view, `Ctrl+Space` collapses a folder |
| `dstat` | CPU / RAM / network of every container, once |
| `dinspect <name>` | `docker inspect` in **fx**: arrows move, `Enter` opens/closes, `/` searches, `q` quits |
| `dsh <name> [bash]` | Shell inside a running container (`sh` by default) |

### SQL clients

- **pgcli / mycli:** autocomplete as you type (`Tab`), Unicode tables, NULL shown
  as `∅` (pgcli), automatic one-column-per-line output when a row is too wide
  (`\x` toggles it by hand), query time after each result. Long results open in
  `less -SRXF`: arrows scroll sideways, `q` leaves. `\dt`, `\d table` work in
  pgcli; `SHOW TABLES`, `DESCRIBE table` in mycli.
- **psql:** same look through `~/.psqlrc`: Unicode borders, `∅` for NULL,
  `\x auto`, `\timing`, one history file per database.
- **hq (harlequin):** full-screen IDE: table tree on the left, editor on the top
  right, results below. `Ctrl+Enter` runs the query, `F1` shows the help.
  `hq "postgres://user:pass@localhost:5432/db"` or `hq -a mysql …`,
  `hq file.duckdb`, `hq file.sqlite`.
- **lzq (lazysql):** browse tables and rows with the keyboard (`Ctrl+E` opens the
  query editor). Connections are saved in `~/.config/lazysql/` (it holds
  passwords, so it is not in the repo).
- **usql:** one client for many databases: `usql postgres://…`, `usql mysql://…`,
  `usql sqlite:file.db`. Same backslash commands as psql.

### JSON, CSV and other tables

- `curl … | fx` or `fx file.json`: browse JSON; `jless file.json` is the lighter
  alternative (`q` quits, `Space` folds). `jq '.items[] | .name'` for scripts.
- `csv file.csv` (csvlens): `hjkl`/arrows scroll, `/` searches, `f` filters
  columns, `q` quits. Also reads a pipe: `psql -A -F, … | csv`.
- `vd file` (visidata): a spreadsheet in the terminal for CSV, JSON, Excel,
  SQLite… `Shift+F` frequency table of a column, `[` / `]` sort, `q` back,
  `Ctrl+q` quit.

### Colors

`ping`, `dig`, `df`, `ps`, `ss`, `mount`, `traceroute`, `netstat` and `nmap` go
through **grc**, which colors their output (only when printing to the screen,
pipes stay plain). `LESS=-RFXi` makes every pager keep colors, not clear the
screen and search ignoring case.
