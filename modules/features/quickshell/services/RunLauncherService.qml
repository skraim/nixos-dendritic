pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false

    function toggle() {
        if (visible) { dismiss() } else { PopupManager.dismissAll(); visible = true }
    }

    function dismiss() {
        visible = false
    }

    IpcHandler {
        target: "run"
        function toggle(): void { root.toggle() }
    }
}
