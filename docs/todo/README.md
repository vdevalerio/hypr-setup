# To-do list

Daily to-do list in the plain [todo.txt](http://todotxt.org) format: one task per
line, finished tasks start with `x DATE`. Data: `~/.local/share/todo/todo.txt`
(part of the restic backup). Script: `~/.config/hypr/scripts/todo.sh`; the `todo`
command (`~/.local/bin/todo`) calls it.

## Command line

| Command | Action |
| --- | --- |
| `todo` / `todo list` | Pending tasks, numbered |
| `todo list -a` | Also the finished ones |
| `todo add "buy coffee"` | Add a task |
| `todo done 2` | Finish task 2 (numbers as listed by `todo`) |
| `todo undo 1` | Reopen the 1st finished task (numbers from `todo list -a`) |
| `todo rm 2` | Delete task 2 |
| `todo clear` | Delete all finished tasks |
| `todo edit` | Open the file in `$EDITOR` (Neovim by default) |

Numbers are positions in the list, so they shift after `done` or `rm`: every
command prints the updated list.

## Bar and menu

- **Waybar** (status island, first item): a checklist icon with the pending count.
  Gray icon = nothing pending. Hover for the first 12 tasks; click to open the menu.
- **Menu** (`SUPER + CTRL + T`, or click the icon): a Rofi list with pending (☐)
  and finished (☑) tasks. Pick a task to finish or reopen it, type text and press
  `Enter` to add a new one. The menu stays open for the next action; `Esc` closes.
  `SUPER + CTRL + T` again closes it.
- Edits made from the terminal, the menu or by hand (`todo edit`) refresh the bar
  right away (Waybar signal 13); otherwise it refreshes every 5 minutes.

## Good to know

- Editing the file by hand is fine: keep one task per line and use `x ` at the
  start of a line for finished ones.
- Setup details: `todo` module in `config.jsonc` (`custom/todo`), style in
  `style.css`, bind in `binds.lua`.
