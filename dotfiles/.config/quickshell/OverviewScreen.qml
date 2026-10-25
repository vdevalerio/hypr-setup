// One screen of the overview (overview.qml): this monitor's workspaces in a grid, with the windows
// at their real position and size, as live thumbnails.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    required property var overview
    required property var colors

    readonly property var hmon: Hyprland.monitorFor(screen)
    readonly property bool focusedScreen: hmon !== null && Hyprland.focusedMonitor === hmon

    // This monitor's workspaces (the fixed 1–5 and the occupied ones, as in the bar) + a "new" one at the end
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.monitor === hmon)
        .sort((a, b) => a.id - b.id)
    readonly property int base: workspaces.length ? Math.floor((workspaces[0].id - 1) / 10) * 10 : 0
    readonly property int nextFree: {
        for (let n = 1; n <= 10; n++)
            if (!workspaces.some(w => w.id === base + n)) return base + n
        return -1
    }
    readonly property var cards: workspaces.map(w => ({ id: w.id, ws: w }))
        .concat(nextFree > 0 ? [{ id: nextFree, ws: null }] : [])

    // Geometry: each card is the monitor to scale
    readonly property real monW: screen.width
    readonly property real monH: screen.height
    readonly property int cols: cards.length <= 6 ? Math.max(1, cards.length) : Math.ceil(cards.length / 2)
    readonly property real gap: 22
    readonly property real cardW: Math.min((width * 0.9 - gap * (cols - 1)) / cols, width * 0.2)
    readonly property real cardH: cardW * monH / monW
    readonly property real k: cardW / monW

    property int selected: 0
    property var dragging: null          // HyprlandToplevel sendo arrastado
    property point dragPos: Qt.point(0, 0)

    function iconFor(cls) {
        const e = DesktopEntries.heuristicLookup(cls || "")
        return Quickshell.iconPath(e ? e.icon : (cls || ""), "application-x-executable")
    }

    function activate(i) {
        const c = cards[i]
        if (c) overview.focusWorkspace(c.id)
    }

    function cardAt(item, x, y) {
        for (let i = 0; i < cardRepeater.count; i++) {
            const card = cardRepeater.itemAt(i)
            const p = card.mapFromItem(item, x, y)
            if (p.x >= 0 && p.y >= 0 && p.x <= card.width && p.y <= card.height) return i
        }
        return -1
    }

    // Opens at 0 and animates to 1; disappears only after the exit animation
    property real progress: overview.shown ? 1 : 0
    Behavior on progress { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    visible: progress > 0

    onVisibleChanged: if (visible) {
        const i = cards.findIndex(c => hmon && hmon.activeWorkspace && c.id === hmon.activeWorkspace.id)
        selected = Math.max(0, i)
        keys.forceActiveFocus()
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: overview.shown && focusedScreen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        opacity: win.progress

        Keys.onPressed: event => {
            const o = win.overview
            const n = win.cards.length
            switch (event.key) {
            case Qt.Key_Escape: o.filter.length ? o.filter = "" : o.close(); break
            case Qt.Key_Return: case Qt.Key_Enter: o.filter.length ? o.focusFirstMatch() : win.activate(win.selected); break
            case Qt.Key_Right: case Qt.Key_Tab: win.selected = (win.selected + 1) % n; break
            case Qt.Key_Left: case Qt.Key_Backtab: win.selected = (win.selected - 1 + n) % n; break
            case Qt.Key_Down: win.selected = Math.min(n - 1, win.selected + win.cols); break
            case Qt.Key_Up: win.selected = Math.max(0, win.selected - win.cols); break
            case Qt.Key_Backspace: o.filter = o.filter.slice(0, -1); break
            default:
                // With no filter, 1–9/0 go straight to the workspace; everything else types into the filter
                if (!o.filter.length && event.text.length === 1 && "1234567890".includes(event.text)) {
                    o.focusWorkspace(win.base + ("1234567890".indexOf(event.text) + 1))
                } else if (event.text.length === 1 && event.text >= " ") {
                    o.filter += event.text
                } else return
            }
            event.accepted = true
        }

        // Background: darkens (with the layer rule blur) and closes when clicking outside the cards
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(win.colors.crust, 0.6)
            MouseArea { anchors.fill: parent; onClicked: win.overview.close() }
        }

        // Filtro
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: grid.y - height - 34
            width: Math.max(260, filterText.implicitWidth + 48)
            height: 40
            radius: 20
            color: Qt.alpha(win.colors.base, 0.85)
            border.width: 1
            border.color: win.overview.filter.length ? win.colors.mauve : Qt.alpha(win.colors.mauve, 0.3)
            visible: win.focusedScreen
            Text {
                id: filterText
                anchors.centerIn: parent
                text: win.overview.filter.length ? "\u{f0349}  " + win.overview.filter
                                                  : "\u{f0349}  Type to filter windows"
                color: win.overview.filter.length ? win.colors.text : win.colors.overlay0
                font.family: win.colors.mono
                font.pixelSize: 15
            }
        }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: win.cols
            spacing: win.gap
            scale: 0.94 + 0.06 * win.progress

            Repeater {
                id: cardRepeater
                model: win.cards

                Item {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property var ws: modelData.ws
                    readonly property bool current: ws !== null && win.hmon && win.hmon.activeWorkspace === ws
                    readonly property bool chosen: win.focusedScreen && win.selected === index
                    readonly property bool dropTarget: win.dragging !== null
                        && win.cardAt(dragLayer, win.dragPos.x, win.dragPos.y) === index
                    width: win.cardW
                    height: win.cardH
                    z: (win.dragging && ws && win.dragging.workspace === ws) ? 2 : 0

                    // Frame: gradient on the current workspace, accent on the one chosen by keyboard
                    Rectangle {
                        id: frame
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: 15
                        scale: card.chosen || card.dropTarget ? 1.03 : 1
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: card.current ? win.colors.mauve
                                : card.chosen || card.dropTarget ? Qt.alpha(win.colors.mauve, 0.8)
                                : cardMouse.containsMouse ? win.colors.surface1 : Qt.alpha(win.colors.surface1, 0.6) }
                            GradientStop { position: 1; color: card.current ? win.colors.blue
                                : card.chosen || card.dropTarget ? Qt.alpha(win.colors.mauve, 0.8)
                                : cardMouse.containsMouse ? win.colors.surface1 : Qt.alpha(win.colors.surface1, 0.6) }
                        }

                        Rectangle {
                            id: inner
                            anchors.fill: parent
                            anchors.margins: card.current || card.chosen || card.dropTarget ? 3 : 1
                            radius: 12
                            color: card.ws ? win.colors.mantle : Qt.alpha(win.colors.mantle, 0.6)
                            clip: true

                            Image {
                                visible: card.ws !== null
                                anchors.fill: parent
                                source: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper/lock.png"
                                fillMode: Image.PreserveAspectCrop
                                opacity: 0.55
                                asynchronous: true
                                sourceSize.width: 480
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: win.overview.focusWorkspace(card.modelData.id)
                            }

                            // Windows at their real position (floating on top)
                            Repeater {
                                model: card.ws ? card.ws.toplevels.values : []
                                delegate: Rectangle {
                                    id: tile
                                    required property var modelData
                                    readonly property var ipc: modelData.lastIpcObject || {}
                                    readonly property var at: ipc.at || [0, 0]
                                    readonly property var sz: ipc.size || [0, 0]
                                    readonly property bool hit: win.overview.matches(modelData)
                                    x: (at[0] - win.hmon.x) * win.k
                                    y: (at[1] - win.hmon.y) * win.k
                                    width: Math.max(8, sz[0] * win.k)
                                    height: Math.max(8, sz[1] * win.k)
                                    z: ipc.floating ? 1 : 0
                                    radius: 6
                                    color: win.colors.surface0
                                    border.width: tileMouse.containsMouse || (win.overview.filter.length && hit) ? 2 : 0
                                    border.color: win.overview.filter.length && hit ? win.colors.mauve : win.colors.text
                                    opacity: win.dragging === modelData ? 0.3 : hit ? 1 : 0.2
                                    clip: true

                                    ScreencopyView {
                                        id: thumb
                                        anchors.fill: parent
                                        anchors.margins: parent.border.width
                                        captureSource: win.visible ? tile.modelData.wayland : null
                                        live: win.overview.shown
                                    }
                                    Image {
                                        anchors.centerIn: parent
                                        readonly property real s: Math.min(48, Math.min(parent.width, parent.height) * 0.45)
                                        width: s; height: s
                                        sourceSize: Qt.size(64, 64)
                                        source: win.iconFor(tile.ipc.class)
                                        visible: !thumb.hasContent
                                    }

                                    MouseArea {
                                        id: tileMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        property point start
                                        onPressed: m => start = Qt.point(m.x, m.y)
                                        onPositionChanged: m => {
                                            if (!pressed) return
                                            if (!win.dragging && Math.hypot(m.x - start.x, m.y - start.y) > 6)
                                                win.dragging = tile.modelData
                                            if (win.dragging) win.dragPos = mapToItem(dragLayer, m.x, m.y)
                                        }
                                        onReleased: m => {
                                            if (!win.dragging) return
                                            const i = win.cardAt(dragLayer, win.dragPos.x, win.dragPos.y)
                                            const target = win.cards[i]
                                            if (target && target.ws !== card.ws)
                                                win.overview.moveWindow(tile.modelData.address, target.id)
                                            win.dragging = null
                                        }
                                        onClicked: if (!win.dragging) win.overview.focusWindow(tile.modelData.address)
                                    }
                                }
                            }

                            // "New" card: empty, with a +
                            Text {
                                anchors.centerIn: parent
                                visible: card.ws === null
                                text: "\u{f0415}"
                                color: win.colors.overlay0
                                font.family: win.colors.mono
                                font.pixelSize: Math.min(42, win.cardH * 0.3)
                            }
                        }
                    }

                    // Workspace number (1–10 on this monitor)
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; margins: 8 }
                        width: label.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: card.current ? win.colors.mauve : Qt.alpha(win.colors.crust, 0.75)
                        visible: card.ws !== null
                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: card.modelData.id - win.base
                            color: card.current ? win.colors.crust : win.colors.text
                            font.family: win.colors.mono
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                }
            }
        }

        // Window being dragged: follows the mouse on top of everything
        Item {
            id: dragLayer
            anchors.fill: parent
            Rectangle {
                visible: win.dragging !== null
                readonly property var ipc: win.dragging ? win.dragging.lastIpcObject || {} : {}
                width: Math.min(220, (ipc.size ? ipc.size[0] : 400) * win.k)
                height: width * (ipc.size ? ipc.size[1] / ipc.size[0] : 0.6)
                x: win.dragPos.x - width / 2
                y: win.dragPos.y - height / 2
                radius: 8
                color: win.colors.surface0
                border.width: 2
                border.color: win.colors.mauve
                clip: true
                ScreencopyView {
                    anchors.fill: parent
                    anchors.margins: 2
                    captureSource: win.dragging ? win.dragging.wayland : null
                    live: true
                }
            }
        }
    }
}
