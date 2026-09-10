pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var data: ({})
    readonly property string dataFile: Quickshell.env("HOME") + "/.cache/quickshell/picker-usage.json"

    Component.onCompleted: reader.running = true

    function get(key) {
        return data[key] || 0
    }

    function record(key) {
        const d = Object.assign({}, data)
        d[key] = (d[key] || 0) + 1
        data = d
        saveDebounce.restart()
    }

    Timer {
        id: saveDebounce
        interval: 500
        repeat: false
        onTriggered: root._doSave()
    }

    function _doSave() {
        const json = JSON.stringify(data)
        writer.command = ["bash", "-c", "printf '%s' '" + json + "' > " + dataFile]
        writer.running = true
    }

    Process {
        id: reader
        property string buf: ""
        command: ["cat", root.dataFile]
        stdout: SplitParser { onRead: line => reader.buf += line }
        onExited: {
            try { if (buf.length > 0) root.data = JSON.parse(buf) } catch(e) {}
            buf = ""
        }
    }

    Process { id: writer }
}
