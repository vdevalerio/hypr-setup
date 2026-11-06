# Configuration

```
~/.config/hypr/
├── hyprland.lua        main file: options, autostart, requires the rest
├── binds.lua           all keybinds (each has a description)
├── rules.lua           window and layer rules
├── workspaces.lua      per-monitor workspace numbering
├── monitors.lua        applies monitors.conf
├── monitors.conf       per-monitor settings (written by the control center)
├── colors.lua          GENERATED from the theme
├── look.conf           font %, gaps, scale (written by look.sh)
├── hypridle.conf       idle timers
├── hyprlock.conf       fallback lock screen
├── themes/             theme.py and palettes/
└── scripts/            helpers
```

## Workflow

1. Edit the live file.
2. Validate: `hyprctl configerrors` (empty output is good).
3. Reload: `hyprctl reload` (Hyprland also reloads on save).
4. Copy it into the repo with `./install.sh save`, commit, push.

The Lua API is documented in `/usr/share/hypr/stubs/hl.meta.lua`. To test a
dispatcher from the shell: `hyprctl dispatch 'hl.dsp.window.close()'`.

## Adding a keybind

```lua
bind(M("SHIFT + K"), hl.dsp.exec_cmd("kitty -e btop"), "System monitor")
```

Always pass a description: it appears in `SUPER + F1`.

## Generated files

Files with an `AUTO-GENERATED … do not edit` header (colors, fonts) come from
`theme.py` and `look.sh`; change the generator, not the output.
See [theming](../theming/README.md).
