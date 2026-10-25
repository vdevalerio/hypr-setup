// hypr-setup login screen — same look as the lock screen (~/.config/hypr/hyprlock.conf).
// Background, colors and photo come from dynamic/ (updated by ~/.config/hypr/scripts/sddm-sync.sh).
// Test without leaving the session: sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/hypr-setup
import QtQuick
import QtQuick.Controls
import QtMultimedia

Rectangle {
    id: root
    color: config.crust || "#11111b"

    // hyprlock measurements are in logical pixels of a 900 px tall screen (1080p at 1.2 scale)
    readonly property real s: height / 900
    readonly property string sans: "Adwaita Sans"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property color textColor: config.text || "#cdd6f4"
    readonly property color accent: config.accent || "#cba6f7"
    readonly property color accent2: config.accent2 || "#89b4fa"

    property string userName: userModel.lastUser
    property string realName: ""
    property int sessionIndex: sessionModel.lastIndex
    property var sessionNames: []
    property bool failed: false
    property date now: new Date()

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // Full name and session list (SDDM models can only be read through delegates)
    Repeater {
        model: userModel
        Item {
            Component.onCompleted: {
                if (!root.userName && index === 0) root.userName = model.name   // no "last user"
                if (model.name === root.userName) root.realName = model.realName
            }
        }
    }
    Repeater {
        model: sessionModel
        Item { Component.onCompleted: { var n = root.sessionNames.slice(); n[index] = model.name; root.sessionNames = n } }
    }

    function greeting() {
        var h = now.getHours()
        var g = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
        var first = (realName || userName || "").split(" ")[0]
        return g + (first ? ", " + first : "")
    }

    function login() {
        if (password.text.length === 0) return
        failed = false
        sddm.login(root.userName, password.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.failed = true
            password.text = ""
            shake.restart()
        }
    }

    // ── Background ──────────────────────────────────────────────────
    // Still image underneath (shows immediately and stays if there's no video); on top, the
    // animated wallpaper (dynamic/background.mp4, already blurred), when the wallpaper is a video or GIF.
    Image {
        anchors.fill: parent
        source: "dynamic/background.jpg"
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: false
    }

    MediaPlayer {
        id: bgPlayer
        source: Qt.resolvedUrl("dynamic/background.mp4")
        videoOutput: bgVideo
        loops: MediaPlayer.Infinite
        Component.onCompleted: play()
    }

    VideoOutput {
        id: bgVideo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        opacity: bgPlayer.playbackState === MediaPlayer.PlayingState ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }

    // Position as in hyprlock: positive y = above center
    function cy(y, item) { return root.height / 2 - y * s - item.height / 2 }

    // ── Date and time ────────────────────────────────────────────
    Text {
        id: dateText
        text: Qt.formatDate(root.now, "dddd  ·  MMMM d").toUpperCase()
        color: "#aaffffff"
        font { family: root.sans; pixelSize: 13 * 1.33 * s; weight: Font.Medium; letterSpacing: 1.5 * s }
        anchors.horizontalCenter: parent.horizontalCenter
        y: cy(250, dateText)
    }

    Text {
        id: clock
        textFormat: Text.StyledText
        text: Qt.formatTime(root.now, "HH") + "<font color='#73ffffff'>:</font>" + Qt.formatTime(root.now, "mm")
        color: root.textColor
        font { family: root.sans; pixelSize: 108 * 1.33 * s; weight: Font.Light }
        anchors.horizontalCenter: parent.horizontalCenter
        y: cy(165, clock)
    }

    Text {
        id: greet
        text: root.greeting()
        color: root.accent
        font { family: root.sans; pixelSize: 15 * 1.33 * s; weight: Font.Medium }
        anchors.horizontalCenter: parent.horizontalCenter
        y: cy(75, greet)
    }

    // ── Center card: avatar + password ─────────────────────────
    Rectangle {
        id: card
        width: 380 * s; height: 230 * s
        radius: 28 * s
        color: "#0dffffff"
        border { width: 1; color: "#22ffffff" }
        anchors.horizontalCenter: parent.horizontalCenter
        y: cy(-95, card)
    }

    // Gradient ring + photo (or icon)
    Rectangle {
        id: ring
        width: 84 * s; height: width; radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: cy(-35, ring)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.accent }
            GradientStop { position: 1; color: root.accent2 }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 4 * s; height: width; radius: width / 2
            color: Qt.darker(config.base || "#1e1e2e", 1.1)
            Text {
                anchors.centerIn: parent
                visible: face.status !== Image.Ready
                text: "󰀄"
                color: root.textColor
                font { family: root.mono; pixelSize: 30 * 1.33 * s }
            }
            Image {
                id: face
                anchors.fill: parent
                source: "dynamic/face.png"
                fillMode: Image.PreserveAspectCrop
                cache: false
                smooth: true
                mipmap: true
            }
        }
    }

    // Password field
    Rectangle {
        id: field
        width: 300 * s; height: 50 * s; radius: height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: cy(-150, field)
        color: "#55000000"
        border {
            width: 2 * s
            color: root.failed ? (config.red || "#f38ba8")
                 : keyboard.capsLock ? (config.yellow || "#f9e2af")
                 : root.accent
        }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        SequentialAnimation on anchors.horizontalCenterOffset {
            id: shake
            running: false
            loops: 2
            NumberAnimation { to: 10 * s; duration: 50 }
            NumberAnimation { to: -10 * s; duration: 80 }
            NumberAnimation { to: 0; duration: 50 }
        }

        TextInput {
            id: password
            anchors { fill: parent; leftMargin: 22 * s; rightMargin: 22 * s }
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password
            passwordCharacter: "●"
            color: root.textColor
            font { family: root.mono; pixelSize: 14 * s; letterSpacing: 3 * s }
            focus: true
            clip: true
            onAccepted: root.login()
            onTextChanged: if (text.length > 0) root.failed = false
            Keys.onEscapePressed: text = ""
        }

        Text {
            anchors.centerIn: parent
            visible: password.text.length === 0
            text: root.failed ? "󰀦  Wrong password"
                : keyboard.capsLock ? "󰪛  Caps Lock is on"
                : "󰌾  Password"
            color: root.failed ? (config.red || "#f38ba8") : "#99ffffff"
            font { family: root.mono; pixelSize: 14 * s; italic: !root.failed }
        }
    }

    // ── Footer ─────────────────────────────────────────────────
    readonly property real bottomY: height - 28 * s

    // Session (click to switch)
    Text {
        id: sessionText
        x: 32 * s
        y: root.bottomY - height
        text: "󰕮  " + (root.sessionNames[root.sessionIndex] || "Hyprland")
        color: sessionArea.containsMouse ? root.textColor : "#ccffffff"
        font { family: root.mono; pixelSize: 12 * 1.33 * s }
        MouseArea {
            id: sessionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessionModel.rowCount())
        }
    }

    // Keyboard layout
    Text {
        id: layoutText
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.bottomY - height
        text: "󰌌  " + (keyboard.layouts.length > 0 ? keyboard.layouts[keyboard.currentLayout].shortName : "br")
        color: "#88ffffff"
        font { family: root.mono; pixelSize: 11 * 1.33 * s }
    }

    // Power
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 32 * s
        y: root.bottomY - height
        spacing: 22 * s
        Repeater {
            model: [
                { icon: "󰤄", show: sddm.canSuspend,  act: function() { sddm.suspend() } },
                { icon: "󰜉", show: sddm.canReboot,   act: function() { sddm.reboot() } },
                { icon: "󰐥", show: sddm.canPowerOff, act: function() { sddm.powerOff() } }
            ]
            Text {
                visible: modelData.show
                text: modelData.icon
                color: powerArea.containsMouse ? root.accent : "#ccffffff"
                font { family: root.mono; pixelSize: 14 * 1.33 * s }
                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.act()
                }
            }
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
