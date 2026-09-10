pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var  _openFns: ({})   // screen.name → openFn
    property var  _menu:    null   // currently active menu for kb navigation

    readonly property string activeMonitorName: {
        const m = [...Hyprland.monitors.values].find(m => m.focused)
        return m?.name
            ?? HyprlandData.activeWindowData?.monitor?.name
            ?? HyprlandData.activeWorkspace?.monitor?.name
            ?? ""
    }

    property bool trayMenuOpen: false
    property bool trayMenuKbOpen: false
    property bool traySubMenuOpen: false
    property var  trayMenuScreen: null
    property real trayMenuWidth: 215

    signal trayMenuClosed()

    function register(screen, openFn) {
        const fns = Object.assign({}, _openFns)
        fns[screen.name] = openFn
        _openFns = fns
    }

    function unregister(screen, openFn) {
        if (_openFns[screen.name] === openFn) {
            const fns = Object.assign({}, _openFns)
            delete fns[screen.name]
            _openFns = fns
        }
    }

    function setActiveMenu(menu) { _menu = menu }

    function _activeScreenName() {
        const monName = activeMonitorName
        if (!monName) return null
        for (const screen of Quickshell.screens) {
            const m = Hyprland.monitorFor(screen)
            if (m && m.name === monName) return screen.name
        }
        return null
    }

    function requestTrayMenu(index) {
        const name = _activeScreenName()
        if (name && _openFns[name]) { _openFns[name](index); return }
        const first = Object.keys(_openFns)[0]
        if (first) _openFns[first](index)
    }

    function navigateUp()           { if (_menu) _menu.kbNavigateUp() }
    function navigateDown()         { if (_menu) _menu.kbNavigateDown() }
    function activate()             { if (_menu) _menu.kbActivate() }
    function goBack()               { if (_menu) _menu.kbGoBack() }
    function closeTrayNav()         { if (_menu) _menu.close() }
    function notifyTrayMenuClosed() { trayMenuClosed() }
}
