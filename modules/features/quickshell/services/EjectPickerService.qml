pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool visible: false

    function show() {
        PopupManager.dismissAll()
        checker.found = false
        checker.running = true
    }

    function dismiss() { visible = false }

    function mountedRemovableDevice(line) {
        const removable = /(?:^| )RM="1"/.test(line)
        const mountpoint = /(?:^| )MOUNTPOINT="([^"]*)"/.exec(line)
        return removable && mountpoint && /^(\/media|\/run\/media)/.test(mountpoint[1])
    }

    Process {
        id: checker
        property bool found: false
        command: ["lsblk", "-P", "-o", "NAME,RM,MOUNTPOINT,MODEL"]
        stdout: SplitParser { onRead: data => { if (root.mountedRemovableDevice(data)) checker.found = true } }
        onRunningChanged: if (running) found = false
        onExited: (exitCode) => {
            if (exitCode === 0 && found)
                root.visible = true
            else
                Quickshell.execDetached(["notify-send", Localization.t("notifications.eject.noDevices.title", "No devices"), Localization.t("notifications.eject.noDevices.body", "No removable devices mounted"), "-a", "Shell"])
        }
    }
}
