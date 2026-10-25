// Tela de bloqueio (Quickshell): mesmo visual do hyprlock/SDDM, com o wallpaper animado.
// Chamada por ~/.config/hypr/scripts/lock.sh (lock_cmd do hypridle); se falhar, o lock.sh usa o hyprlock.
// Usa o protocolo ext-session-lock: se este processo cair, o Hyprland mantém a sessão bloqueada.
// Teste sem digitar senha: QS_LOCK_TEST=8 qs -p ~/.config/quickshell/lock.qml   (desbloqueia sozinho em 8 s)
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    // Estado compartilhado por todas as telas: digitar em qualquer monitor vale para todos
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
        config: "hyprlock"   // /etc/pam.d/hyprlock (inclui o login padrão)
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

    // Some com uma transição curta e só então libera a sessão
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
