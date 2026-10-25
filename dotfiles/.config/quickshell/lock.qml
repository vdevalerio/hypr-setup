// Lock screen (Quickshell): same look as hyprlock/SDDM, with the animated wallpaper.
// Called by ~/.config/hypr/scripts/lock.sh (hypridle lock_cmd); if it fails, lock.sh falls back to hyprlock.
// Uses the ext-session-lock protocol: if this process dies, Hyprland keeps the session locked.
// Test without typing a password: QS_LOCK_TEST=8 qs -p ~/.config/quickshell/lock.qml   (unlocks by itself after 8 s)
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    // State shared by all screens: typing on any monitor applies to all of them
    property string password: ""
    property bool failed: false
    property bool busy: false
    property bool unlocking: false

    Theme { id: colors }

    function submit() {
        if (password.length === 0 || busy) return
        busy = true
        failed = false
        pam.start()
    }

    PamContext {
        id: pam
        config: "hyprlock"   // /etc/pam.d/hyprlock (includes the default login)
        onPamMessage: if (responseRequired) respond(root.password)
        onCompleted: result => {
            root.busy = false
            if (result === PamResult.Success) {
                root.unlocking = true
                unlockTimer.start()
            } else {
                root.failed = true
                root.password = ""
            }
        }
        onError: () => { root.busy = false; root.failed = true; root.password = "" }
    }

    // Fades out with a short transition and only then releases the session
    Timer {
        id: unlockTimer
        interval: 300
        onTriggered: { lock.locked = false; Qt.quit() }
    }

    Timer {
        readonly property int seconds: parseInt(Quickshell.env("QS_LOCK_TEST") || "0")
        running: seconds > 0
        interval: seconds * 1000
        onTriggered: { root.unlocking = true; unlockTimer.start() }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            color: colors.crust
            LockSurface {
                anchors.fill: parent
                shell: root
                theme: colors
            }
        }
    }
}
