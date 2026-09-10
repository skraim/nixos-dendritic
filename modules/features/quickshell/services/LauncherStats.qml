pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var counts: ({})

    FileView {
        id: statsFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/launcher-stats.json"
        // preload: true by default — loads automatically at startup

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

    // Call this every time an app is launched
    function recordLaunch(appId) {
        const c = Object.assign({}, root.counts)
        c[appId] = (c[appId] || 0) + 1
        root.counts = c
        statsFile.setText(JSON.stringify(c))
    }

    // Sort apps by descending launch count, alphabetically for ties
    function sortApps(apps) {
        return [...apps].sort((a, b) => {
            const diff = (root.counts[b.id] || 0) - (root.counts[a.id] || 0)
            return diff !== 0 ? diff : a.name.localeCompare(b.name)
        })
    }
}
