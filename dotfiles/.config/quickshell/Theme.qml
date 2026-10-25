// Cores do tema atual (~/.config/quickshell/colors.json, gerado por ~/.config/hypr/themes/theme.py).
// Recarrega sozinho quando o tema muda. Mesmos nomes do Catppuccin: mauve = acento principal,
// blue = segundo tom dos gradientes.
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme
    property var c: ({})
    readonly property color mauve:    c.mauve    || "#cba6f7"
    readonly property color blue:     c.blue     || "#89b4fa"
    readonly property color pink:     c.pink     || "#f5c2e7"
    readonly property color red:      c.red      || "#f38ba8"
    readonly property color yellow:   c.yellow   || "#f9e2af"
    readonly property color green:    c.green    || "#a6e3a1"
    readonly property color text:     c.text     || "#cdd6f4"
    readonly property color subtext0: c.subtext0 || "#a6adc8"
    readonly property color overlay0: c.overlay0 || "#6c7086"
    readonly property color surface0: c.surface0 || "#313244"
    readonly property color surface1: c.surface1 || "#45475a"
    readonly property color base:     c.base     || "#1e1e2e"
    readonly property color mantle:   c.mantle   || "#181825"
    readonly property color crust:    c.crust    || "#11111b"
    readonly property string sans: "Adwaita Sans"
    readonly property string mono: "JetBrainsMono Nerd Font"

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: try { theme.c = JSON.parse(text()) } catch (e) {}
    }
}
