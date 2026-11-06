# Document readers

## Zathura (PDF)

Keyboard-driven, themed from the system colors (`~/.config/zathura/colors`).

| Keys | Action |
| --- | --- |
| `j` `k` / `h` `l` | Scroll |
| `Space` / `Shift+Space` | Page down / up |
| `J` / `K` or `PgDn` / `PgUp` | Next / previous page |
| `gg` / `G` | First / last page |
| `<n>G` | Go to page n |
| `+` `-` `=` | Zoom in / out / reset (`a` best fit, `s` fit width) |
| `r` | Rotate |
| `/` `?` then `n` `N` | Search |
| `Tab` | Table of contents |
| `Ctrl+r` | Recolor (night mode with theme colors) |
| `d` | Dual-page mode |
| `Ctrl+m` | Hide the status bar |
| `q` | Quit |

## Foliate (e-books)

EPUB reader with text-to-speech through Piper (`./install.sh tts`). Pick a
voice with `SUPER + SHIFT + V` (it is used for every book, whatever language its metadata declares;
Piper voices: pt-BR faber, en-US ryan, en-GB alan). The sentence being read is highlighted in blue and the word in yellow. Highlights, notes and bookmarks are
in the sidebar; `Ctrl+f` searches.

## Speechify

Installed as a web app (Brave) for reading text aloud.

## mpv and imv

`mpv` plays video/audio (`Space` pause, `←/→` seek, `f` fullscreen, `q` quit);
`imv` views images (`←/→` previous/next, `+/-` zoom, `q` quit).

### Read-aloud controls (Foliate)

`foliate-sentences` (launcher override) patches the viewer through GResource
overlays. Reading starts at the current page; to start elsewhere, select the
text and press `Ctrl+Return` (or use "Speak from Here" in the selection menu).

| Keys | Action |
| --- | --- |
| `Ctrl+Space` | Play / pause |
| `Ctrl+.` / `Ctrl+,` | Next / previous sentence |
| `Ctrl+Alt+.` / `Ctrl+Alt+,` | Next / previous paragraph |
| `Ctrl+Backspace` | Stop |
| `Ctrl+Return` | Read from the selected text |

`Ctrl+arrows` are not usable: the web view consumes them.

The keys also work with the selection popover open (it has its own key
controller). They are registered in the capture phase and the callbacks return
`true`: otherwise GTK keeps propagating, the toggle runs twice (pause + resume)
and `Ctrl+.` opens the emoji picker.

Word highlight: `sd_piper` emits `<sentence mark>#<n>` marks (n = index of the
whitespace-separated word in the sentence) between Foliate's sentence marks; the
Foliate overlay paints both with the CSS Custom Highlight API (`::highlight`)
instead of selecting the text.
