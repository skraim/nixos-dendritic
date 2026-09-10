pragma ComponentBehavior: Bound

import qs.utils
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var menuHandle: null
    property real iconScreenY: 0
    property bool isClosing: false

    // Navigation: depth 0 = root (rootOpener), depth 1 = submenu (subOpener)
    property var  menuStack: []          // length > 0 means we're in a submenu
    property var  activeSubHandle: null  // submenu handle; null = at root

    // Keyboard navigation
    property bool kbNavActive: false
    property int  kbSelectedIndex: -1
    property bool kbBackSelected: false   // true = Back button is highlighted
    property bool openedFromKeyboard: false

    property bool anyItemHovered: false

    property real menuWidth: 210
    property real maxMenuWidth: 210   // never shrinks while menu is open; reset on open()
    property real maxMenuHeight: 0   // max target height seen; reset on open()
    onMenuWidthChanged: {
        BarNavigationService.trayMenuWidth = menuWidth + 5
        if (menuWidth > maxMenuWidth) maxMenuWidth = menuWidth
    }

    // Hidden text sizer — real Text items so implicitWidth is accurate
    Item {
        visible: false; width: 0; height: 0
        Repeater {
            id: sizerRepeater
            model: root.menuStack.length > 0 ? subOpener.children : rootOpener.children
            delegate: Text {
                required property var modelData
                visible: false
                text: modelData.isSeparator ? "" : modelData.text
                font.pointSize: 10
            }
            onCountChanged: Qt.callLater(root.updateMenuWidth)
        }
    }

    function updateMenuWidth() {
        let maxW = 180
        for (let i = 0; i < sizerRepeater.count; i++) {
            const t = sizerRepeater.itemAt(i)
            if (!t || t.modelData.isSeparator) continue
            const extra = 44
                + (t.modelData.buttonType !== QsMenuButtonType.None ? 20 : 0)
                + (t.modelData.hasChildren ? 22 : 0)
            maxW = Math.max(maxW, t.implicitWidth + extra)
        }
        menuWidth = Math.min(Math.max(maxW, 180), 450)
    }

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.left: true
    anchors.top: true
    anchors.bottom: true
    margins.left: 43

    implicitWidth: root.maxMenuWidth + 60

    // rootOpener.menu never changes after open() — its children stay alive
    QsMenuOpener {
        id: rootOpener
        menu: root.menuHandle
    }

    // subOpener tracks the current submenu level
    QsMenuOpener {
        id: subOpener
        menu: root.activeSubHandle
    }

    Timer {
        id: mouseExitTimer
        interval: 400
        onTriggered: {
            if (!root.kbNavActive) root.close()
        }
    }

    Connections {
        target: subOpener
        function onChildrenChanged() {
            Qt.callLater(function() {
                if (root.kbNavActive && root.kbSelectedIndex < 0 && menuRepeater.count > 0) {
                    root.kbSelectedIndex = root.nextSelectableIndex(-1, 1)
                }
            })
        }
    }

    Connections {
        target: rootOpener
        function onChildrenChanged() {
            Qt.callLater(function() {
                if (root.kbNavActive && root.menuStack.length === 0 && root.kbSelectedIndex < 0 && menuRepeater.count > 0) {
                    root.kbSelectedIndex = root.nextSelectableIndex(-1, 1)
                }
            })
        }
    }

    // ── Public keyboard-navigation API (called from WhichKey via BarNavigationService) ──
    function kbNavigateUp() {
        if (kbBackSelected) return  // already at top
        if (kbSelectedIndex < 0) { kbSelectedIndex = nextSelectableIndex(-1, 1); return }
        const prev = nextSelectableIndex(kbSelectedIndex, -1)
        if (prev === kbSelectedIndex && menuStack.length > 0) {
            // at first item and in submenu → jump to Back
            kbBackSelected = true
            kbSelectedIndex = -1
        } else {
            kbSelectedIndex = prev
        }
    }
    function kbNavigateDown() {
        if (kbBackSelected) {
            kbBackSelected = false
            kbSelectedIndex = nextSelectableIndex(-1, 1)
            return
        }
        if (kbSelectedIndex < 0) kbSelectedIndex = nextSelectableIndex(-1, 1)
        else kbSelectedIndex = nextSelectableIndex(kbSelectedIndex, 1)
    }
    function kbActivate() { activateSelected() }
    function kbGoBack()   { navigateBack() }

    // ── Navigation ─────────────────────────────────────────────────────────────
    // menuStack holds the activeSubHandle of each level we navigated FROM,
    // so navigateBack() can restore the previous level's handle.
    // null = came from root (rootOpener); otherwise the parent subHandle.
    function navigateInto(handle) {
        menuStack = [...menuStack, activeSubHandle]  // push current level's handle
        activeSubHandle = handle
        kbSelectedIndex = -1
        kbBackSelected = false
        anyItemHovered = false
        mouseExitTimer.stop()
        BarNavigationService.traySubMenuOpen = true
    }

    function navigateBack() {
        if (menuStack.length === 0) { close(); return }
        const prev = menuStack[menuStack.length - 1]
        menuStack = menuStack.slice(0, -1)          // pop
        activeSubHandle = prev                       // null → root, handle → parent submenu
        kbSelectedIndex = -1
        kbBackSelected = false
        anyItemHovered = false
        mouseExitTimer.stop()
        BarNavigationService.traySubMenuOpen = menuStack.length > 0
    }

    // ── Internal helpers ────────────────────────────────────────────────────────
    function nextSelectableIndex(current, direction) {
        const count = menuRepeater.count
        if (count === 0) return -1
        let idx = (current < 0 && direction > 0) ? 0 : current + direction
        while (idx >= 0 && idx < count) {
            const d = menuRepeater.itemAt(idx)
            if (d && !d.modelData.isSeparator && d.modelData.enabled) return idx
            idx += direction
        }
        return current < 0 ? -1 : current
    }

    function activateSelected() {
        if (kbBackSelected) { navigateBack(); return }
        if (kbSelectedIndex < 0 || kbSelectedIndex >= menuRepeater.count) return
        const d = menuRepeater.itemAt(kbSelectedIndex)
        if (!d) return
        const item = d.modelData
        if (!item || item.isSeparator || !item.enabled) return
        if (item.hasChildren) navigateInto(item)
        else { item.triggered(); close() }
    }

    function open(handle, screenY, barTopY) {
        menuCloseAnim.stop()
        mouseExitTimer.stop()
        anyItemHovered = false
        isClosing = false
        kbNavActive = false
        kbSelectedIndex = -1
        openedFromKeyboard = false
        menuHandle = handle
        activeSubHandle = null
        menuStack = []
        maxMenuWidth = 210
        maxMenuHeight = 0
        iconScreenY = screenY
        menuGroup.animScaleX = 0
        menuGroup.animScaleY = 0
        visible = true
        menuOpenAnim.start()
        Qt.callLater(seedMaxBounds)
    }

    function openFromKeyboard(handle, screenY, barTopY) {
        menuCloseAnim.stop()
        mouseExitTimer.stop()
        isClosing = false
        kbNavActive = true
        kbSelectedIndex = -1
        openedFromKeyboard = true
        menuHandle = handle
        activeSubHandle = null
        menuStack = []
        maxMenuWidth = 210
        maxMenuHeight = 0
        iconScreenY = screenY
        menuGroup.animScaleX = 0
        menuGroup.animScaleY = 0
        visible = true
        BarNavigationService.trayMenuKbOpen = true
        BarNavigationService.setActiveMenu(root)
        menuOpenAnim.start()
        Qt.callLater(seedMaxBounds)
    }

    function seedMaxBounds() {
        const h = menuColumn.implicitHeight + 24
        if (h > maxMenuHeight) maxMenuHeight = h
        updateMenuWidth()
    }

    function close() {
        menuOpenAnim.stop()
        mouseExitTimer.stop()
        anyItemHovered = false
        kbNavActive = false
        kbSelectedIndex = -1
        kbBackSelected = false
        BarNavigationService.trayMenuKbOpen = false
        BarNavigationService.traySubMenuOpen = false
        if (openedFromKeyboard) {
            openedFromKeyboard = false
            BarNavigationService.notifyTrayMenuClosed()
        }
        isClosing = true
        menuCloseAnim.start()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: root.close()
    }

    MouseArea {
        id: menuProximity
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        x: 0
        y: {
            const effH = Math.max(menuGroup.height, root.maxMenuHeight)
            const effY = Math.min(root.iconScreenY - Globals.componentRadius, root.height - effH - 8)
            return Math.max(0, effY - 50)
        }
        width: Math.min(root.width, menuGroup.x + Math.max(menuGroup.width, root.maxMenuWidth + 5) + 50)
        height: {
            const effH = Math.max(menuGroup.height, root.maxMenuHeight)
            const effY = Math.min(root.iconScreenY - Globals.componentRadius, root.height - effH - 8)
            const top    = Math.max(0, effY - 50)
            const bottom = Math.min(root.height, effY + effH + 50)
            return Math.max(0, bottom - top)
        }
        onEntered: mouseExitTimer.stop()
        onExited: {
            if (!root.kbNavActive && !root.isClosing && !root.anyItemHovered)
                mouseExitTimer.restart()
        }

    }

    Item {
        id: menuGroup
        x: 20
        y: Math.min(root.iconScreenY - Globals.componentRadius, root.height - height - 8)

        width: root.menuWidth + 5
        height: menuColumn.implicitHeight + 24
        clip: false

        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        property real animScaleX: 1
        property real animScaleY: 1

        transform: Scale {
            xScale: menuGroup.animScaleX
            yScale: menuGroup.animScaleY
            origin.x: 0
            origin.y: Math.max(0, Math.min(root.iconScreenY - menuGroup.y, menuGroup.height))
        }

        SequentialAnimation {
            id: menuOpenAnim
            NumberAnimation { target: menuGroup; property: "animScaleX"; from: 0; to: 1; duration: 120; easing.type: Easing.OutCubic }
            NumberAnimation { target: menuGroup; property: "animScaleY"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
        }

        SequentialAnimation {
            id: menuCloseAnim
            NumberAnimation { target: menuGroup; property: "animScaleY"; from: 1; to: 0; duration: 120; easing.type: Easing.InCubic }
            NumberAnimation { target: menuGroup; property: "animScaleX"; from: 1; to: 0; duration: 80; easing.type: Easing.InCubic }
            ScriptAction { script: { root.visible = false; root.isClosing = false; root.menuStack = []; root.activeSubHandle = null } }
        }

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0; verticalOffset: 2
            radius: 16; samples: 28; color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.5)
        }

        Rectangle {
            anchors.fill: parent
            color: MatugenColors.md3.background
            radius: Globals.componentRadius
            clip: true

            ColumnLayout {
                id: menuColumn
                anchors { fill: parent; margins: 4 }
                spacing: 0

                // ── Back button ───────────────────────────────────────────────
                Item {
                    id: backItem
                    Layout.fillWidth: true
                    implicitHeight: root.menuStack.length > 0 ? 26 : 0
                    visible: root.menuStack.length > 0
                    clip: true

                    Rectangle {
                        anchors { fill: parent; margins: 2 }
                        radius: 4
                        color: (backMouse.containsMouse || (root.kbNavActive && root.kbBackSelected))
                            ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.85)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                            spacing: 5

                            Text {
                                text: "arrow_back"
                                font.family: "Material Symbols Rounded"
                                font.variableAxes: ({ "FILL": 1 })
                                renderType: Text.NativeRendering
                                font.pixelSize: 12
                                color: MatugenColors.md3.on_background; opacity: 0.4
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                text: Localization.t("trayMenu.back", "Back")
                                font.pointSize: 9
                                color: MatugenColors.md3.on_background; opacity: 0.4
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: { root.anyItemHovered = true; mouseExitTimer.stop() }
                            onExited:  { root.anyItemHovered = false }
                            onClicked: root.navigateBack()
                        }
                    }
                }

                // ── Separator after Back ──────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: root.menuStack.length > 0 ? 9 : 0
                    visible: root.menuStack.length > 0
                    clip: true
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 12; height: 1
                        color: Qt.color(MatugenColors.md3.on_surface_variant); opacity: 0.4
                    }
                }

                // ── Menu items ────────────────────────────────────────────────
                Repeater {
                    id: menuRepeater
                    model: root.menuStack.length > 0 ? subOpener.children : rootOpener.children
                    delegate: Item {
                        id: entryItem
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: entryItem.modelData.isSeparator ? 9 : 28

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 12; height: 1
                            color: Qt.color(MatugenColors.md3.on_surface_variant); opacity: 0.4
                            visible: entryItem.modelData.isSeparator
                        }

                        Rectangle {
                            anchors { fill: parent; margins: 2 }
                            radius: 4
                            visible: !entryItem.modelData.isSeparator
                            color: (itemMouse.containsMouse
                                    || (root.kbNavActive && root.kbSelectedIndex === entryItem.index))
                                   && entryItem.modelData.enabled
                                   ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.7)
                                   : "transparent"
                            Behavior on color { ColorAnimation { duration: 40 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                                spacing: 6

                                Text {
                                    Layout.preferredWidth: (entryItem.modelData.buttonType !== QsMenuButtonType.None) ? 14 : 0
                                    visible: entryItem.modelData.buttonType !== QsMenuButtonType.None
                                    text: entryItem.modelData.checkState === Qt.Checked ? "✓" : ""
                                    color: Qt.color(MatugenColors.md3.primary)
                                    font.pointSize: 9; verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: entryItem.modelData.text
                                    color: entryItem.modelData.enabled
                                           ? Qt.color(MatugenColors.md3.on_background)
                                           : ColorUtils.transparentize(MatugenColors.md3.on_background, 0.5)
                                    font.pointSize: 10; elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    visible: entryItem.modelData.hasChildren
                                    text: "chevron_right"
                                    font.family: "Material Symbols Rounded"
                                    font.variableAxes: ({ "FILL": 1 })
                                    renderType: Text.NativeRendering
                                    font.pointSize: 12
                                    verticalAlignment: Text.AlignVCenter
                                    color: ColorUtils.transparentize(MatugenColors.md3.on_background, 0.4)
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !entryItem.modelData.isSeparator && entryItem.modelData.enabled
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.anyItemHovered = true
                                    mouseExitTimer.stop()
                                }
                                onExited: {
                                    root.anyItemHovered = false
                                }
                                onClicked: {
                                    if (entryItem.modelData.hasChildren)
                                        root.navigateInto(entryItem.modelData)
                                    else {
                                        entryItem.modelData.triggered()
                                        root.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: menuColumn
        function onImplicitHeightChanged() {
            const h = menuColumn.implicitHeight + 24
            if (h > root.maxMenuHeight) root.maxMenuHeight = h
        }
    }
}
