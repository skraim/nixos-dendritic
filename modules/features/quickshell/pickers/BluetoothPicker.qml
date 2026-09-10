import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Qt5Compat.GraphicalEffects
import qs.services
import qs.utils

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusiveZone: -1
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            anchors.top: true; anchors.bottom: true
            anchors.left: true; anchors.right: true
            visible: btWindow.visible
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: btWindow.isOpen ? 0.5 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: BluetoothPickerService.dismiss()
            }
        }
    }

    PanelWindow {
        id: btWindow

        property bool isOpen: false
        property string selectedAddress: ""
        readonly property int currentIdx: {
            if (!selectedAddress) return -1
            const pi = content.filteredPaired.findIndex(d => d && d.address === selectedAddress)
            if (pi >= 0) return pi
            const di = content.filteredDiscovered.findIndex(d => d && d.address === selectedAddress)
            return di >= 0 ? content.filteredPaired.length + di : -1
        }
        readonly property var adapter: Bluetooth.defaultAdapter
        property var pendingConnectDevice: null
        property bool mouseActive: false

        visible: isOpen || closeTimer.running
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        anchors.top: true; anchors.bottom: true
        anchors.left: true; anchors.right: true

        // ── Service wiring ─────────────────────────────────────────────────
        Connections {
            target: BluetoothPickerService
            function onVisibleChanged() {
                if (BluetoothPickerService.visible) {
                    btWindow.isOpen = true
                } else {
                    closeTimer.restart()
                    btWindow.isOpen = false
                }
            }
        }

        onIsOpenChanged: {
            if (isOpen) {
                mouseActive = false
                searchInput.text = ""
                const pArr = content.filteredPaired
                const dArr = content.filteredDiscovered
                if (pArr.length > 0) selectedAddress = pArr[0].address
                else if (dArr.length > 0) selectedAddress = dArr[0].address
                else selectedAddress = ""
                searchInput.forceActiveFocus()
            } else {
                if (adapter) adapter.discovering = false
            }
        }

        // ── Navigation ──────────────────────────────────────────────────────
        function navigate(delta) {
            mouseActive = false
            const pArr = content.filteredPaired
            const dArr = content.filteredDiscovered
            const total = pArr.length + dArr.length
            if (total === 0) return
            const cur = currentIdx < 0 ? 0 : currentIdx
            const next = (cur + delta + total) % total
            const item = next < pArr.length ? pArr[next] : dArr[next - pArr.length]
            if (item) selectedAddress = item.address
        }

        function activateCurrent() {
            const pArr = content.filteredPaired
            const dArr = content.filteredDiscovered
            const idx = currentIdx
            if (idx < 0) return
            if (idx < pArr.length) {
                const dev = pArr[idx]
                if (dev.connected) {
                    dev.disconnect()
                } else {
                    UsageTracker.record("bt:" + dev.address)
                    dev.connect()
                    btWindow.pendingConnectDevice = dev
                }
            } else {
                const dev = dArr[idx - pArr.length]
                if (dev) { dev.connect(); btWindow.pendingConnectDevice = dev }
            }
        }

        function toggleDiscovery() {
            if (adapter) adapter.discovering = !adapter.discovering
        }

        Timer { id: closeTimer; interval: 220; repeat: false }
        Timer { id: autoCloseTimer; interval: 1000; repeat: false; onTriggered: BluetoothPickerService.dismiss() }

        Connections {
            target: btWindow.pendingConnectDevice
            function onConnectedChanged() {
                if (btWindow.pendingConnectDevice && btWindow.pendingConnectDevice.connected) {
                    autoCloseTimer.restart()
                    btWindow.pendingConnectDevice = null
                }
            }
        }

        Keys.onEscapePressed: BluetoothPickerService.dismiss()

        MouseArea { anchors.fill: parent; enabled: btWindow.isOpen; onClicked: BluetoothPickerService.dismiss() }

        // ── Center panel ────────────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.35)
            width: 660
            height: mainRect.height

            opacity: btWindow.isOpen ? 1.0 : 0.0
            scale:   btWindow.isOpen ? 1.0 : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }
            HoverHandler { onPointChanged: btWindow.mouseActive = true }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 2
                radius: 12; samples: 22; color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.5)
            }

            Rectangle {
                id: mainRect
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: content.implicitHeight + 24
                color: MatugenColors.md3.surface
                radius: Globals.componentRadius
                clip: true

                ColumnLayout {
                    id: content
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
                    spacing: 8

                    property var filteredPaired: {
                        if (!btWindow.adapter || !btWindow.adapter.devices) return []
                        const q = searchInput.text.trim().toLowerCase()
                        const devs = btWindow.adapter.devices.values.filter(d => d && (d.paired || d.trusted))
                        const filtered = q.length === 0 ? devs : devs.filter(d => d.name.toLowerCase().includes(q))
                        return filtered.slice().sort((a, b) => {
                            if (a.connected !== b.connected) return a.connected ? -1 : 1
                            const ua = UsageTracker.get("bt:" + a.address)
                            const ub = UsageTracker.get("bt:" + b.address)
                            if (ua !== ub) return ub - ua
                            return a.name.localeCompare(b.name)
                        })
                    }
                    property var filteredDiscovered: {
                        if (!btWindow.adapter || !btWindow.adapter.devices) return []
                        const q = searchInput.text.trim().toLowerCase()
                        const devs = btWindow.adapter.devices.values.filter(d => d && !d.paired && !d.trusted)
                        const filtered = q.length === 0 ? devs : devs.filter(d => d.name.toLowerCase().includes(q))
                        return filtered.slice().reverse()
                    }
                    property bool showNearby: (btWindow.adapter && btWindow.adapter.discovering)
                                              || filteredDiscovered.length > 0

                    // ── Search bar ──────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        color: MatugenColors.md3.surface_container
                        radius: Globals.componentRadius

                        RowLayout {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            spacing: 10

                            Text {
                                font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                font.variableAxes: ({ "FILL": 1 })
                                renderType: Text.NativeRendering
                                color: MatugenColors.md3.on_surface_variant; opacity: 0.6
                                text: "bluetooth"
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.pixelSize: 16
                                color: MatugenColors.md3.on_surface
                                selectionColor: MatugenColors.md3.primary
                                clip: true
                                onTextChanged: Qt.callLater(function() {
                                    const pArr = content.filteredPaired
                                    const dArr = content.filteredDiscovered
                                    const addr = btWindow.selectedAddress
                                    const stillPresent = pArr.some(d => d && d.address === addr)
                                                      || dArr.some(d => d && d.address === addr)
                                    if (!stillPresent) {
                                        if (pArr.length > 0) btWindow.selectedAddress = pArr[0].address
                                        else if (dArr.length > 0) btWindow.selectedAddress = dArr[0].address
                                        else btWindow.selectedAddress = ""
                                    }
                                })

                                Text {
                                    anchors.fill: parent
                                    text: Localization.t("bluetoothPicker.search", "Search devices...")
                                    font: searchInput.font
                                    color: MatugenColors.md3.on_surface; opacity: 0.3
                                    visible: searchInput.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Keys.onEscapePressed: BluetoothPickerService.dismiss()
                                Keys.onReturnPressed: btWindow.activateCurrent()
                                Keys.onUpPressed:   btWindow.navigate(-1)
                                Keys.onDownPressed: btWindow.navigate(1)
                                Keys.onPressed: function(event) {
                                    const sc = Globals.scanCodes
                                    if ((event.modifiers & Qt.ControlModifier) && event.nativeScanCode === sc['S']) {
                                        btWindow.toggleDiscovery()
                                        event.accepted = true
                                    } else if (event.modifiers & Qt.ControlModifier) {
                                        if (event.nativeScanCode === sc['N']) {
                                            btWindow.navigate(1);  event.accepted = true
                                        } else if (event.nativeScanCode === sc['P']) {
                                            btWindow.navigate(-1); event.accepted = true
                                        }
                                    }
                                }
                            }

                            // Ctrl+S scan badge
                            Rectangle {
                                implicitHeight: 28
                                implicitWidth: scanBadgeRow.implicitWidth + 16
                                radius: Globals.componentRadius - 4
                                color: (btWindow.adapter && btWindow.adapter.discovering)
                                    ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4)
                                    : MatugenColors.md3.surface_container_low
                                Behavior on color { ColorAnimation { duration: 200 } }

                                RowLayout {
                                    id: scanBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Text {
                                        id: scanIcon
                                        readonly property bool scanning: btWindow.adapter && btWindow.adapter.discovering

                                        font.family: "Material Symbols Rounded"; font.pixelSize: 14
                                        font.variableAxes: ({ "FILL": 1 })
                                        renderType: Text.NativeRendering
                                        color: MatugenColors.md3.on_surface
                                        opacity: scanning ? 1.0 : 0.5
                                        text: "sync"
                                        transformOrigin: Item.Center
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                        onScanningChanged: {
                                            if (!scanning)
                                                rotation = 0
                                        }
                                        RotationAnimation on rotation {
                                            running: scanIcon.scanning
                                            from: 0
                                            to: 360
                                            duration: 900
                                            loops: Animation.Infinite
                                        }
                                    }
                                    Text {
                                        text: (btWindow.adapter && btWindow.adapter.discovering) ? Localization.t("bluetoothPicker.scanning", "Scanning...") : "^S"
                                        font.pixelSize: 12
                                        color: MatugenColors.md3.on_surface
                                        opacity: (btWindow.adapter && btWindow.adapter.discovering) ? 0.9 : 0.45
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { btWindow.toggleDiscovery(); searchInput.forceActiveFocus() }
                                }
                            }
                        }
                    }

                    // ── Paired devices ──────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        clip: true
                        implicitHeight: Math.min(content.filteredPaired.length, 7) * 46
                        Behavior on implicitHeight {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }

                        ListView {
                            id: pairedList
                            anchors.fill: parent
                            clip: true
                            model: content.filteredPaired
                            currentIndex: btWindow.currentIdx
                            highlightMoveDuration: 0

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: pairedList.width; height: 46

                                readonly property bool isBusy: modelData.state === BluetoothDeviceState.Connecting
                                                            || modelData.state === BluetoothDeviceState.Disconnecting
                                                            || modelData.pairing
                                readonly property bool isSelected: index === btWindow.currentIdx

                                Rectangle {
                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                                    color: isSelected
                                        ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
                                    radius: Globals.componentRadius - 4
                                    Behavior on color { ColorAnimation { duration: 40 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                        spacing: 12

                                        Text {
                                            id: pairSpinner
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                            font.variableAxes: ({ "FILL": 1 })
                                            renderType: Text.NativeRendering
                                            color: MatugenColors.md3.primary; text: "progress_activity"
                                            visible: isBusy
                                            NumberAnimation on rotation {
                                                from: 0; to: 360; duration: 900
                                                loops: Animation.Infinite; running: pairSpinner.visible
                                            }
                                        }
                                        Text {
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                            font.variableAxes: ({ "FILL": 1 })
                                            renderType: Text.NativeRendering
                                            color: modelData.connected ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                                            opacity: modelData.connected ? 0.9 : 0.45
                                            text: modelData.connected ? "bluetooth_searching" : "bluetooth"
                                            visible: !isBusy
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            font.pixelSize: 15
                                            color: MatugenColors.md3.on_surface
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: isBusy
                                                ? (modelData.state === BluetoothDeviceState.Disconnecting ? Localization.t("bluetoothPicker.status.disconnecting", "Disconnecting...") : Localization.t("bluetoothPicker.status.connecting", "Connecting..."))
                                                : modelData.connected ? Localization.t("bluetoothPicker.status.connected", "Connected") : Localization.t("bluetoothPicker.status.paired", "Paired")
                                            font.pixelSize: 12
                                            color: isBusy ? MatugenColors.md3.primary
                                                 : modelData.connected ? MatugenColors.md3.primary
                                                 : MatugenColors.md3.on_surface
                                            opacity: isBusy ? 0.9 : modelData.connected ? 0.75 : 0.35
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: 120
                                            Behavior on color   { ColorAnimation  { duration: 200 } }
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }
                                    }

                                    MouseArea {
                                        id: pairArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { if (btWindow.mouseActive) btWindow.selectedAddress = modelData.address }
                                        onClicked: {
                                            if (modelData.connected) {
                                                modelData.disconnect()
                                            } else {
                                                UsageTracker.record("bt:" + modelData.address)
                                                modelData.connect()
                                                btWindow.pendingConnectDevice = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: pairedList.contentHeight > pairedList.height
                            anchors { right: parent.right; rightMargin: 4; top: parent.top; bottom: parent.bottom }
                            width: 3; radius: 1.5
                            color: MatugenColors.md3.outline_variant
                            Rectangle {
                                width: parent.width
                                height: pairedList.height > 0
                                    ? Math.max(24, (pairedList.height / pairedList.contentHeight) * pairedList.height) : 0
                                y: pairedList.height > 0
                                    ? (pairedList.contentY / pairedList.contentHeight) * pairedList.height : 0
                                radius: parent.radius
                                color: MatugenColors.md3.on_surface_variant; opacity: 0.6
                            }
                        }
                    }

                    // ── Nearby / discovered section ─────────────────────────
                    Item {
                        Layout.fillWidth: true
                        clip: true
                        implicitHeight: content.showNearby
                            ? (28 + Math.min(content.filteredDiscovered.length, 5) * 46)
                            : 0
                        Behavior on implicitHeight {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }

                        ColumnLayout {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            spacing: 0

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                RowLayout {
                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2 }
                                    spacing: 8
                                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: MatugenColors.md3.outline_variant }
                                    Text {
                                        text: (btWindow.adapter && btWindow.adapter.discovering) ? Localization.t("bluetoothPicker.nearbyScanning", "Nearby  -  Scanning...") : Localization.t("bluetoothPicker.status.nearby", "Nearby")
                                        font.pixelSize: 11
                                        color: MatugenColors.md3.on_surface; opacity: 0.4
                                    }
                                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: MatugenColors.md3.outline_variant }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: Math.min(content.filteredDiscovered.length, 5) * 46

                                ListView {
                                    id: discoveredList
                                    anchors.fill: parent
                                    clip: true
                                    model: content.filteredDiscovered
                                    currentIndex: btWindow.currentIdx - content.filteredPaired.length
                                    highlightMoveDuration: 0

                                    delegate: Item {
                                        required property var modelData
                                        required property int index
                                        width: discoveredList.width; height: 46

                                        readonly property bool isBusy: modelData.state === BluetoothDeviceState.Connecting
                                                                    || modelData.pairing
                                        readonly property bool isSelected: btWindow.currentIdx - content.filteredPaired.length === index

                                        Rectangle {
                                            anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                                            color: isSelected
                                                ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
                                            radius: Globals.componentRadius - 4
                                            Behavior on color { ColorAnimation { duration: 40 } }

                                            RowLayout {
                                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                                spacing: 12

                                                Text {
                                                    id: discSpinner
                                                    font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                                    font.variableAxes: ({ "FILL": 1 })
                                                    renderType: Text.NativeRendering
                                                    color: MatugenColors.md3.primary; text: "progress_activity"
                                                    visible: isBusy
                                                    NumberAnimation on rotation {
                                                        from: 0; to: 360; duration: 900
                                                        loops: Animation.Infinite; running: discSpinner.visible
                                                    }
                                                }
                                                Text {
                                                    font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                                    font.variableAxes: ({ "FILL": 1 })
                                                    renderType: Text.NativeRendering
                                                    color: MatugenColors.md3.on_surface; opacity: 0.4
                                                    text: "bluetooth"
                                                    visible: !isBusy
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.name
                                                    font.pixelSize: 15
                                                    color: MatugenColors.md3.on_surface
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: isBusy ? Localization.t("bluetoothPicker.status.connecting", "Connecting...") : Localization.t("bluetoothPicker.status.nearby", "Nearby")
                                                    font.pixelSize: 12
                                                    color: isBusy ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                                                    opacity: isBusy ? 0.9 : 0.35
                                                    Behavior on color   { ColorAnimation  { duration: 200 } }
                                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                                }
                                            }

                                            MouseArea {
                                                id: discArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onEntered: { if (btWindow.mouseActive) btWindow.selectedAddress = modelData.address }
                                                onClicked: { modelData.connect(); btWindow.pendingConnectDevice = modelData }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: discoveredList.contentHeight > discoveredList.height
                                    anchors { right: parent.right; rightMargin: 4; top: parent.top; bottom: parent.bottom }
                                    width: 3; radius: 1.5
                                    color: MatugenColors.md3.outline_variant
                                    Rectangle {
                                        width: parent.width
                                        height: discoveredList.height > 0
                                            ? Math.max(24, (discoveredList.height / discoveredList.contentHeight) * discoveredList.height) : 0
                                        y: discoveredList.height > 0
                                            ? (discoveredList.contentY / discoveredList.contentHeight) * discoveredList.height : 0
                                        radius: parent.radius
                                        color: MatugenColors.md3.on_surface_variant; opacity: 0.6
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
