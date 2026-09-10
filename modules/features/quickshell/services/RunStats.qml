pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var counts: ({})
    property var customCmds: []

    FileView {
        id: statsFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/run-stats.json"

        onLoadedChanged: {
            if (!loaded) return
            try {
                const parsed = JSON.parse(statsFile.text())
                if (parsed && typeof parsed === "object")
                    root.counts = parsed
            } catch (_) {
                root.counts = {}
            }
        }
    }

    FileView {
        id: customCmdsFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/run-custom-cmds.json"

        onLoadedChanged: {
            if (!loaded) return
            try {
                const parsed = JSON.parse(customCmdsFile.text())
                if (Array.isArray(parsed))
                    root.customCmds = parsed
            } catch (_) {
                root.customCmds = []
            }
        }
    }

    function recordLaunch(cmd) {
        const c = Object.assign({}, root.counts)
        c[cmd] = (c[cmd] || 0) + 1
        root.counts = c
        statsFile.setText(JSON.stringify(c))
    }

    function saveCustomCmd(cmd) {
        if (root.customCmds.includes(cmd)) return
        const updated = [...root.customCmds, cmd]
        root.customCmds = updated
        customCmdsFile.setText(JSON.stringify(updated))
    }

    // Sort commands: by descending launch count, then alphabetically
    function sortCmds(cmds) {
        return [...cmds].sort((a, b) => {
            const diff = (root.counts[b] || 0) - (root.counts[a] || 0)
            return diff !== 0 ? diff : a.localeCompare(b)
        })
    }
}
