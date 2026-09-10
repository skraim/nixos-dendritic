pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false

    function toggle() {
        visible = !visible
    }

    function dismiss() {
        visible = false
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { root.toggle() }
    }
}
