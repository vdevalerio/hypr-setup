// Content of a locked screen (one instance per monitor). Same measurements as hyprlock and the
// SDDM theme (~/hypr-setup/system/sddm/hypr-setup/Main.qml): pixels of a 900-pixel-tall screen.
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io

Item {
    id: surface
    required property var shell
    required property var theme

    readonly property real s: height / 900
    readonly property string home: Quickshell.env("HOME")
    readonly property string sddmDynamic: "/usr/share/sddm/themes/hypr-setup/dynamic"
    property date now: new Date()
    property bool capsLock: false
    property string battery: ""
    property string realName: ""

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: surface.now = new Date() }

    function greeting() {
        var h = now.getHours()
        var g = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
        var name = (surface.realName || Quickshell.env("USER") || "").split(" ")[0]
        return g + (name ? ", " + name : "")
    }
    function glyph(cp) { return String.fromCodePoint(cp) }

    // User account full name (GECOS field), as on the login screen
    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector { onStreamFinished: surface.realName = text.trim() }
    }

    // Caps Lock and battery (read from the system every half second / 30 s)
    Process {
        id: capsProc
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | sort -r | head -1"]
        stdout: StdioCollector { onStreamFinished: surface.capsLock = text.trim() !== "" && text.trim() !== "0" }
    }
    Timer { interval: 500; running: true; repeat: true; triggeredOnStart: true; onTriggered: capsProc.running = true }
    Process {
        id: batProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: surface.battery = text.trim() }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: batProc.running = true }

    // ── Background: blurred wallpaper image; on top, the video (when the wallpaper is animated) ──
    Image {
        anchors.fill: parent
        source: "file://" + surface.home + "/.cache/wallpaper/lock.png"
        fillMode: Image.PreserveAspectCrop
        cache: false
    }
    MediaPlayer {
        id: player
        source: "file://" + surface.sddmDynamic + "/background.mp4"
        videoOutput: video
        loops: MediaPlayer.Infinite
        Component.onCompleted: play()
    }
    VideoOutput {
        id: video
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        opacity: player.playbackState === MediaPlayer.PlayingState ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }

    // Everything fades out together on unlock
    Item {
        id: content
        anchors.fill: parent
        opacity: surface.shell.unlocking ? 0 : 1
        scale: surface.shell.unlocking ? 1.04 : 1
        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        // Position as in hyprlock: positive y = above the center
        function cy(y, item) { return content.height / 2 - y * surface.s - item.height / 2 }

        Text {
            id: dateText
            text: Qt.formatDate(surface.now, "dddd  ·  MMMM d").toUpperCase()
            color: "#aaffffff"
            font { family: surface.theme.sans; pixelSize: 13 * 1.33 * surface.s; weight: Font.Medium; letterSpacing: 1.5 * surface.s }
            anchors.horizontalCenter: parent.horizontalCenter
            y: content.cy(250, dateText)
        }
        Text {
            id: clock
            textFormat: Text.StyledText
            text: Qt.formatTime(surface.now, "HH") + "<font color='#73ffffff'>:</font>" + Qt.formatTime(surface.now, "mm")
            color: surface.theme.text
            font { family: surface.theme.sans; pixelSize: 108 * 1.33 * surface.s; weight: Font.Light }
            anchors.horizontalCenter: parent.horizontalCenter
            y: content.cy(165, clock)
        }
        Text {
            id: greet
            text: surface.greeting()
            color: surface.theme.mauve
            font { family: surface.theme.sans; pixelSize: 15 * 1.33 * surface.s; weight: Font.Medium }
            anchors.horizontalCenter: parent.horizontalCenter
            y: content.cy(75, greet)
        }

        // Central card
        Rectangle {
            id: card
            width: 380 * surface.s; height: 230 * surface.s
            radius: 28 * surface.s
            color: "#0dffffff"
            border { width: 1; color: "#22ffffff" }
            anchors.horizontalCenter: parent.horizontalCenter
            y: content.cy(-95, card)
        }

        // Gradient ring + photo (~/.face) or icon
        Rectangle {
            id: ring
            width: 84 * surface.s; height: width; radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: content.cy(-35, ring)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: surface.theme.mauve }
                GradientStop { position: 1; color: surface.theme.blue }
            }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 4 * surface.s; height: width; radius: width / 2
                color: Qt.darker(surface.theme.base, 1.1)
                Text {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    text: surface.glyph(0xF0004)
                    color: surface.theme.text
                    font { family: surface.theme.mono; pixelSize: 30 * 1.33 * surface.s }
                }
                // Photo cropped to a circle (Qt clip is rectangular; the mask does the rounding)
                Image {
                    id: face
                    anchors.fill: parent
                    source: "file://" + surface.home + "/.face"
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    smooth: true
                    mipmap: true
                    visible: false
                }
                Rectangle {
                    id: faceMask
                    anchors.fill: parent
                    radius: width / 2
                    layer.enabled: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: face
                    visible: face.status === Image.Ready
                    maskEnabled: true
                    maskSource: faceMask
                }
            }
        }

        // Password field
        Rectangle {
            id: field
            width: 300 * surface.s; height: 50 * surface.s; radius: height / 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: content.cy(-150, field)
            color: "#55000000"

            // Gradient border (as in hyprlock): gradient cut into a ring by a mask
            readonly property color c1: surface.shell.failed ? surface.theme.red
                                      : surface.capsLock ? surface.theme.yellow : surface.theme.mauve
            readonly property color c2: surface.shell.failed ? surface.theme.red
                                      : surface.capsLock ? surface.theme.yellow : surface.theme.blue
            Rectangle {
                id: fieldGradient
                anchors.fill: parent
                radius: parent.radius
                visible: false
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: field.c1; Behavior on color { ColorAnimation { duration: 200 } } }
                    GradientStop { position: 1; color: field.c2; Behavior on color { ColorAnimation { duration: 200 } } }
                }
            }
            Item {
                id: fieldHole
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle {
                    anchors { fill: parent; margins: 2 * surface.s }
                    radius: height / 2
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: fieldGradient
                maskEnabled: true
                maskInverted: true
                maskSource: fieldHole
                opacity: surface.shell.busy ? 0.5 : 1
            }

            SequentialAnimation on anchors.horizontalCenterOffset {
                id: shake
                running: false
                loops: 2
                NumberAnimation { to: 10 * surface.s; duration: 50 }
                NumberAnimation { to: -10 * surface.s; duration: 80 }
                NumberAnimation { to: 0; duration: 50 }
            }
            Connections {
                target: surface.shell
                function onFailedChanged() { if (surface.shell.failed) shake.restart() }
            }

            TextInput {
                id: input
                anchors { fill: parent; leftMargin: 22 * surface.s; rightMargin: 22 * surface.s }
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: surface.theme.text
                font { family: surface.theme.mono; pixelSize: 14 * surface.s; letterSpacing: 3 * surface.s }
                focus: true
                clip: true
                enabled: !surface.shell.busy
                text: surface.shell.password
                onTextChanged: {
                    if (text !== surface.shell.password) surface.shell.password = text
                    if (text.length > 0) surface.shell.failed = false
                }
                onAccepted: surface.shell.submit()
                Keys.onEscapePressed: surface.shell.password = ""
                Component.onCompleted: forceActiveFocus()
            }

            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0
                text: surface.shell.busy ? surface.glyph(0xF0450) + "  Checking…"
                    : surface.shell.failed ? surface.glyph(0xF0026) + "  Wrong password"
                    : surface.capsLock ? surface.glyph(0xF0BEA) + "  Caps Lock is on"
                    : surface.glyph(0xF033E) + "  Password"
                color: surface.shell.failed ? surface.theme.red : "#99ffffff"
                font { family: surface.theme.mono; pixelSize: 14 * surface.s; italic: !surface.shell.failed }
            }
        }

        // Footer: battery
        Text {
            visible: surface.battery !== ""
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: 32 * surface.s; bottomMargin: 28 * surface.s }
            text: surface.glyph(0xF0079) + "  " + surface.battery + "%"
            color: "#ccffffff"
            font { family: surface.theme.mono; pixelSize: 12 * 1.33 * surface.s }
        }
        Text {
            anchors { left: parent.left; bottom: parent.bottom; leftMargin: 32 * surface.s; bottomMargin: 28 * surface.s }
            text: surface.glyph(0xF033E) + "  Locked"
            color: "#88ffffff"
            font { family: surface.theme.mono; pixelSize: 12 * 1.33 * surface.s }
        }
    }
}
