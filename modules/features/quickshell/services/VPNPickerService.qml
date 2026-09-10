pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool visible: false

    function show() {
        PopupManager.dismissAll()
        visible = true
    }

    function dismiss() { visible = false }
}
