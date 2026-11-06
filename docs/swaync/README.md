# SwayNC (notifications)

Notification daemon and center. Config: `~/.config/swaync/config.json`, style in
`style.css`; `colors.css` and `font.css` are generated.

| Keys | Action |
| --- | --- |
| `SUPER + N` | Open / close the notification center |
| `SUPER + SHIFT + N` | Clear all notifications |

Commands:

```sh
swaync-client -t -sw      # toggle the center
swaync-client -C -sw      # clear everything
swaync-client -d -sw      # toggle Do Not Disturb
swaync-client -rs         # reload the style
notify-send "Title" "Body"
```

Volume, brightness and caps-lock indicators are also swaync notifications
(`app-name osd`, replaced in place so they do not stack).
