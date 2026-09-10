pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false
    property string group: ""

    function toggle(grp) {
        if (visible && group === grp) {
            visible = false
            group = ""
        } else if (visible) {
            // switching groups — don't close, just update
            group = grp
        } else {
            PopupManager.dismissAllExceptDashboard()
            group = grp
            visible = true
        }
    }

    function dismiss() {
        visible = false
        group = ""
    }

    IpcHandler {
        target: "whichkey"
        function toggle(group: string): void { root.toggle(group) }
    }
}
