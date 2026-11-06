# Configuration

The live files in `~/.config/nvim` are the source of truth. After editing them
run `./install.sh save` in the repo to copy them into `dotfiles/.config/nvim`.

```
~/.config/nvim/
├── init.lua              bootstraps lazy.nvim (do not edit)
├── lazyvim.json          LazyVim extras (none enabled)
├── lazy-lock.json        pinned plugin versions
├── stylua.toml           Lua formatting rules (width 80)
├── spell/                personal dictionaries (en, pt, tech)
└── lua/
    ├── config/
    │   ├── lazy.lua      lazy.nvim setup
    │   ├── options.lua   vim options, spell, python LSP
    │   ├── keymaps.lua   extra keymaps (empty for now)
    │   ├── autocmds.lua  loads cleanup.lua
    │   └── cleanup.lua   clean-on-save and <leader>c* commands
    └── plugins/
        ├── colorscheme.lua   Catppuccin, transparent, wallpaper palette
        ├── datascience.lua   REPL, jupytext, CSV, python LSP tweaks
        ├── explorer.lua      <leader>uH dotfiles toggle
        ├── formatting.lua    conform + nvim-lint settings
        ├── diagnostics.lua   full diagnostic message under the cursor line (virtual lines)
        └── markdown.lua      render-markdown: tables stay rendered (and wrapped) in normal mode
```

## Adding a plugin

Create `lua/plugins/<name>.lua` that returns a spec:

```lua
return {
  "author/plugin.nvim",
  opts = { ... },
}
```

Restart Neovim; lazy.nvim installs it. `:Lazy` (`<leader>l`) manages plugins.
To override a LazyVim default, return a spec with the same repo name and the
fields you want to change (`opts` tables are merged).

## Adding a keymap

```lua
-- lua/config/keymaps.lua
vim.keymap.set("n", "<leader>xx", "<cmd>...<cr>", { desc = "My action" })
```

Give every map a `desc`, so which-key and `<leader>sk` show it.

## Extras

`:LazyExtras` browses language/tool extras (DAP, test, other languages). They
write to `lazyvim.json`.

## Theme

`colorscheme.lua` reads `~/.config/hypr/colors.lua`, which `theme.py` rewrites
with the wallpaper palette; Neovim recolors itself when it changes. Backgrounds
are cleared so kitty's transparency shows through.

## Updating

`:Lazy sync` updates plugins; `:Lazy restore` goes back to `lazy-lock.json`;
`:Mason` updates tools. Commit `lazy-lock.json` after a deliberate update.
