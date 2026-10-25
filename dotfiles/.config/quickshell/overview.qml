//@ pragma IconTheme Papirus-Dark
// Workspace overview (SUPER + Tab): each monitor shows its own, with live thumbnails.
// Resident process (autostart in hyprland.lua, on the integrated GPU); the shortcut calls
// ~/.config/hypr/scripts/overview.sh, which toggles via IPC: qs -p <this file> ipc call overview toggle
//   Click a workspace: go to it · click a window: focus it · drag a window: move it to another workspace
//   Arrows/Tab: choose · Enter: go · 1–9/0: jump to workspace · type: filter windows · Esc or click outside: close
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    property bool shown: false
    property string filter: ""

    Theme { id: theme }

    function open() {
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()   // current window positions and sizes
        filter = ""
        shown = true
    }
    function close() { shown = false }

    // Hyprland in Lua: dispatch takes the Lua expression, as in `hyprctl dispatch`
    function dispatch(lua) { Hyprland.dispatch(lua) }
    // Switch workspace/window only after closing: while the layer holds the keyboard
    // (exclusive), Hyprland ignores focus changes elsewhere
    property string pending: ""
    function closeThen(lua) { pending = lua; close(); afterClose.restart() }
    Timer { id: afterClose; interval: 40; onTriggered: { root.dispatch(root.pending); root.pending = "" } }

    function focusWorkspace(id) { closeThen(`hl.dsp.focus({ workspace = "${id}" })`) }
    // HyprlandToplevel.address comes without the "0x"
    function addr(a) { return a.startsWith("0x") ? a : "0x" + a }
    function focusWindow(address) { closeThen(`hl.dsp.focus({ window = "address:${addr(address)}" })`) }
    function moveWindow(address, id) {
        dispatch(`hl.dsp.window.move({ workspace = "${id}", window = "address:${addr(address)}", follow = false })`)
        refresh.restart()
    }

    function matches(toplevel) {
        if (filter.length === 0) return true
        const f = filter.toLowerCase()
        const ipc = toplevel.lastIpcObject || {}
        return (toplevel.title || "").toLowerCase().includes(f) || (ipc.class || "").toLowerCase().includes(f)
    }

    // Enter with a filter: the first matching window (on any monitor)
    function focusFirstMatch() {
        const t = Hyprland.toplevels.values.find(t => t.workspace && t.workspace.id > 0 && matches(t))
        if (t) focusWindow(t.address)
    }

    // Positions and sizes (lastIpcObject) do not arrive via events: re-read after any change,
    // waiting for the window animation to settle
    Timer { id: refresh; interval: 350; onTriggered: Hyprland.refreshToplevels() }
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (root.shown) refresh.restart() }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.shown ? root.close() : root.open() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    Variants {
        model: Quickshell.screens
        OverviewScreen {
            required property var modelData
            screen: modelData
            overview: root
            colors: theme
        }
    }
}
