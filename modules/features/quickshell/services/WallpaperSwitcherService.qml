pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false
    property string activeWallpaper: ""
    property bool syncRunning: false
    property string syncStatus: ""
    readonly property string thumbnailDir: expandPath(Settings.cachePath) + "/wallpaper-thumbnails"

    function toggle() {
        if (visible) {
            dismiss()
        } else {
            refreshActiveWallpaper()
            PopupManager.dismissAll()
            visible = true
        }
    }

    function dismiss() {
        visible = false
    }

    function refreshActiveWallpaper() {
        if (!activeWallpaperQuery.running)
            activeWallpaperQuery.running = true
    }

    function expandPath(path) {
        if (!path)
            return ""
        if (path === "~")
            return Quickshell.env("HOME")
        if (path.indexOf("~/") === 0)
            return Quickshell.env("HOME") + path.slice(1)
        return path.replace("$HOME", Quickshell.env("HOME"))
    }

    function thumbnailFor(path) {
        return thumbnailDir + "/thumb_" + path.split("/").pop() + ".png"
    }

    function sync() {
        if (wallpaperSync.running)
            return

        const sourceDir = expandPath(Settings.wallpapersPath)
        syncStatus = "syncing"
        wallpaperSync.command = ["bash", Quickshell.shellDir + "/scripts/wallpaper-sync.sh", sourceDir, thumbnailDir]
        wallpaperSync.running = true
    }

    function setActiveWallpaper(path) {
        activeWallpaper = path || ""
    }

    Process {
        id: activeWallpaperQuery
        command: ["sh", "-c", Settings.activeWallpaperCmd]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.activeWallpaper = ""
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.activeWallpaper = text.trim().split("\n")[0] || ""
            }
        }
    }

    Process {
        id: wallpaperSync
        running: false
        onRunningChanged: root.syncRunning = running
        onExited: function(exitCode) {
            root.syncStatus = exitCode === 0 ? "synced" : "failed"
        }
    }

    IpcHandler {
        target: "wallpaper"
        function sync(): void { root.sync() }
    }
}
