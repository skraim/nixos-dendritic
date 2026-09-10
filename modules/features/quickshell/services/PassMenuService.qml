pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool visible: false

    function toggle() {
        if (visible) { dismiss() } else { PopupManager.dismissAll(); visible = true }
    }

    function dismiss() {
        visible = false
    }
}
