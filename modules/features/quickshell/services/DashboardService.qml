pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool visible: false
    property int  currentTab: 0
    property var  screen: null

    function toggle() {
        if (visible) { dismiss() } else { PopupManager.dismissAll(); visible = true }
    }
    function dismiss() { visible = false }
    function show(tab) {
        if (visible) {
            PopupManager.dismissAllExceptDashboard()
            currentTab = tab
            return
        }

        PopupManager.dismissAll()
        currentTab = tab
        visible = true
    }
}
