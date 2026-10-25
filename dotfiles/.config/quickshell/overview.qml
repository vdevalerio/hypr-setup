//@ pragma IconTheme Papirus-Dark
// Visão geral dos workspaces (SUPER + Tab): cada monitor mostra os seus, com miniaturas ao vivo.
// Processo residente (autostart no hyprland.lua, pela GPU integrada); o atalho chama
// ~/.config/hypr/scripts/overview.sh, que alterna por IPC: qs -p <este arquivo> ipc call overview toggle
//   Clique no workspace: vai até ele · clique na janela: foca · arraste a janela: move de workspace
//   Setas/hjkl: escolhe · Enter: vai · digite: filtra as janelas · Esc ou clique fora: fecha
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
        Hyprland.refreshToplevels()   // posições e tamanhos atuais das janelas
        filter = ""
        shown = true
    }
    function close() { shown = false }

    // Hyprland em Lua: o dispatch recebe a expressão Lua, como no `hyprctl dispatch`
    function dispatch(lua) { Hyprland.dispatch(lua) }
    // Trocar de workspace/janela só depois de fechar: enquanto a camada segura o teclado
    // (exclusivo), o Hyprland ignora o foco em outro lugar
    property string pending: ""
    function closeThen(lua) { pending = lua; close(); afterClose.restart() }
    Timer { id: afterClose; interval: 40; onTriggered: { root.dispatch(root.pending); root.pending = "" } }

    function focusWorkspace(id) { closeThen(`hl.dsp.focus({ workspace = "${id}" })`) }
    // HyprlandToplevel.address vem sem o "0x"
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

    // Enter com filtro: a primeira janela que combina (em qualquer monitor)
    function focusFirstMatch() {
        const t = Hyprland.toplevels.values.find(t => t.workspace && t.workspace.id > 0 && matches(t))
        if (t) focusWindow(t.address)
    }

    // Posições e tamanhos (lastIpcObject) não chegam por evento: relê depois de qualquer mudança,
    // esperando a animação das janelas assentar
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
