pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root

    property var activeWorkspace: Hyprland.focusedWorkspace
    property var activeWindowData: Hyprland.activeToplevel
    property var monitors: Hyprland.monitors
    property var windowList: Hyprland.toplevels

    property string submap: ""
    property int toplevelsRevision: 0
    property int workspacesRevision: 0
    property int monitorsRevision: 0

    function refreshToplevelState() {
        Hyprland.refreshToplevels();
        root.toplevelsRevision++;
    }

    function refreshWorkspaceState() {
        Hyprland.refreshWorkspaces();
        root.workspacesRevision++;
    }

    function refreshMonitorState() {
        Hyprland.refreshMonitors();
        root.monitorsRevision++;
    }

    function refreshGeometryState() {
        root.refreshToplevelState();
        root.refreshWorkspaceState();
        root.refreshMonitorState();
    }

    Timer {
        id: geometrySettleRefreshTimer
        interval: 80
        repeat: false
        onTriggered: root.refreshGeometryState()
    }

    function fullscreenOnMonitor(monitor) {
        root.toplevelsRevision;
        root.workspacesRevision;
        root.monitorsRevision;

        if (!monitor)
            return false;

        const monId = monitor.id;
        const activeWsId = monitor.activeWorkspace?.id ?? -1;
        return [...root.windowList.values].some(w => w.lastIpcObject?.fullscreen === 2 && w.monitor?.id === monId && w.workspace?.id === activeWsId);
    }

    function biggestWindowForWorkspace(workspaceId) {
        if (workspaceId === undefined || workspaceId === null)
            return null;

        const windowsInThisWorkspace = [...root.windowList.values].filter(w => w.workspace?.id === workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.lastIpcObject?.size?.[0] ?? 0) * (maxWin?.lastIpcObject?.size?.[1] ?? 0);
            const winArea = (win?.lastIpcObject?.size?.[0] ?? 0) * (win?.lastIpcObject?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    function workspaceApps(workspaceId) {
        if (workspaceId === undefined || workspaceId === null)
            return [];

        return [...root.windowList.values].filter(w => w.workspace?.id === workspaceId);
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;

            if (n === "windowtitle" || n === "windowtitlev2")
                return;

            if (n === "submap") {
                root.submap = event.data;
            } else if (["workspace", "workspacev2", "moveworkspace", "moveworkspacev2", "activespecial", "activespecialv2", "focusedmon", "focusedmonv2"].includes(n)) {
                root.refreshGeometryState();
                geometrySettleRefreshTimer.restart();
            } else if (["openwindow", "openwindowv2", "closewindow", "closewindowv2"].includes(n)) {
                root.refreshToplevelState();
                root.refreshWorkspaceState();
            } else if (["movewindow", "movewindowv2"].includes(n)) {
                root.refreshGeometryState();
                geometrySettleRefreshTimer.restart();
            } else if (n.includes("mon")) {
                root.refreshMonitorState();
                geometrySettleRefreshTimer.restart();
            } else if (n.includes("workspace")) {
                root.refreshGeometryState();
                geometrySettleRefreshTimer.restart();
            } else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                root.refreshToplevelState();
            }
        }
    }
}
