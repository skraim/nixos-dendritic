import qs.utils
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: trayLayout.implicitHeight

    required property var barScreen

    property var trayComponents: new Map()  // SystemTrayItem → QML Item
    property var prevItems: []

    TrayMenuPopup {
        id: trayMenu
        screen: root.barScreen
        onVisibleChanged: {
            BarNavigationService.trayMenuOpen = visible
            BarNavigationService.trayMenuScreen = visible ? root.barScreen : null
        }
    }

    function _handleTrayMenu(idx) {
        const items = SystemTray.items.values
        if (idx < 0 || idx >= items.length) return
        const item = items[idx]
        if (!item.hasMenu) return
        const comp = root.trayComponents.get(item)
        const screenY = comp ? comp.mapToGlobal(0, comp.height / 2).y : 0
        trayMenu.openFromKeyboard(item.menu, screenY, root.mapToGlobal(0, 0).y)
    }

    function addItem(trayItem) {
        if (root.trayComponents.has(trayItem)) return
        const comp = trayItemComp.createObject(trayLayout, { trayData: trayItem })
        root.trayComponents.set(trayItem, comp)
        comp.animateIn()
    }

    function removeItem(trayItem) {
        const comp = root.trayComponents.get(trayItem)
        if (!comp) return
        root.trayComponents.delete(trayItem)
        comp.animateOut()
    }

    function sortItems() {
        const items = SystemTray.items.values
        // Re-parenting to the same parent is a no-op in Qt, so we bounce
        // through a buffer to force items to re-append in the correct order.
        for (const item of items) {
            const comp = root.trayComponents.get(item)
            if (comp) comp.parent = sortBuffer
        }
        for (const item of items) {
            const comp = root.trayComponents.get(item)
            if (comp) comp.parent = trayLayout
        }
    }

    Connections {
        target: SystemTray.items
        function onValuesChanged() {
            const current = SystemTray.items.values
            for (const item of current)
                if (!root.trayComponents.has(item)) root.addItem(item)
            for (const item of root.prevItems)
                if (!current.includes(item)) root.removeItem(item)
            root.prevItems = [...current]
            root.sortItems()
        }
    }

    Component.onCompleted: {
        BarNavigationService.register(root.barScreen, _handleTrayMenu)
        const items = SystemTray.items.values
        for (const item of items) root.addItem(item)
        root.prevItems = [...items]
        root.sortItems()
    }
    Component.onDestruction: BarNavigationService.unregister(root.barScreen, _handleTrayMenu)

    Component {
        id: trayItemComp

        Item {
            id: delegate
            property SystemTrayItem trayData
            Layout.fillWidth: true
            implicitHeight: 0
            clip: true

            readonly property int trayIndex: {
                const vals = SystemTray.items.values
                return vals ? vals.indexOf(trayData) : -1
            }

            function animateIn() { showAnim.start() }
            function animateOut() { hideAnim.start() }

            SequentialAnimation {
                id: showAnim
                NumberAnimation { target: delegate; property: "implicitHeight"; to: 28; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: content;  property: "opacity"; to: 1; duration: 150 }
            }
            SequentialAnimation {
                id: hideAnim
                NumberAnimation { target: content;  property: "opacity"; to: 0; duration: 150 }
                NumberAnimation { target: delegate; property: "implicitHeight"; to: 0; duration: 200; easing.type: Easing.OutCubic }
                ScriptAction { script: delegate.destroy() }
            }

            Item {
                id: content
                anchors.fill: parent
                opacity: 0

                Rectangle {
                    anchors { fill: parent; margins: 2 }
                    radius: 6
                    color: mouseArea.containsMouse
                        ? ColorUtils.transparentize(MatugenColors.md3.on_background, 0.85)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    source: delegate.trayData ? delegate.trayData.icon : ""
                    width: 18
                    height: 18
                    smooth: true
                }

                Desaturate {
                    id: desaturatedIcon
                    visible: false
                    anchors.centerIn: parent
                    width: trayIcon.width
                    height: trayIcon.height
                    source: trayIcon
                    desaturation: .6
                }

                ColorOverlay {
                    anchors.fill: desaturatedIcon
                    source: desaturatedIcon
                    color: ColorUtils.transparentize(MatugenColors.md3.tertiary, .75)
                    opacity: 1
                }

                MouseArea {
                    id: mouseArea
                    anchors { fill: parent; margins: -4 }
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (!delegate.trayData) return
                        if (mouse.button === Qt.LeftButton) {
                            delegate.trayData.activate()
                        } else if (mouse.button === Qt.RightButton && delegate.trayData.hasMenu) {
                            trayMenu.open(delegate.trayData.menu,
                                mouseArea.mapToGlobal(0, mouseArea.height / 2).y,
                                root.mapToGlobal(0, 0).y)
                        }
                    }

                    onWheel: function(wheel) {
                        if (delegate.trayData) delegate.trayData.scroll(wheel.angleDelta.y, false)
                    }
                }

                Rectangle {
                    visible: WhichKeyService.visible && WhichKeyService.group === "bar"
                             && !BarNavigationService.trayMenuKbOpen
                             && (Hyprland.monitorFor(root.barScreen)?.name === BarNavigationService.activeMonitorName)
                             && delegate.trayIndex >= 0 && delegate.trayIndex < 9
                    anchors.bottom: trayIcon.bottom
                    anchors.right: trayIcon.right
                    anchors.bottomMargin: -5
                    anchors.rightMargin: -5
                    width: 13; height: 13
                    radius: 3
                    color: MatugenColors.md3.primary

                    Text {
                        anchors.centerIn: parent
                        text: delegate.trayIndex >= 0 ? String(delegate.trayIndex + 1) : ""
                        font.pixelSize: 8
                        font.bold: true
                        color: MatugenColors.md3.background
                    }
                }
            }
        }
    }

    Item { id: sortBuffer; visible: false; width: 0; height: 0 }

    ColumnLayout {
        id: trayLayout
        width: parent.width
        spacing: 0
    }
}
