import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            visible: win.visible
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: win.isOpen ? 0.5 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: VPNPickerService.dismiss()
            }
        }
    }

    PanelWindow {
        id: win

        property bool isOpen: false
        property string selectedVpnName: ""
        readonly property int currentIndex: filteredVPNs.findIndex(v => v.short_name === selectedVpnName)
        property string pendingVpnName: ""
        property bool pendingConnect: false
        property bool mouseActive: false

        property var filteredVPNs: {
            const q = searchInput.text.trim().toLowerCase();
            const base = q.length === 0 ? Settings.vpns : Settings.vpns.filter(v => v.short_name.toLowerCase().includes(q));
            return base.slice().sort((a, b) => {
                const ac = win.isConnected(a), bc = win.isConnected(b);
                if (ac !== bc)
                    return ac ? -1 : 1;
                const ua = UsageTracker.get("vpn:" + a.short_name);
                const ub = UsageTracker.get("vpn:" + b.short_name);
                if (ua !== ub)
                    return ub - ua;
                return a.short_name.localeCompare(b.short_name);
            });
        }

        visible: isOpen || closeTimer.running
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        Connections {
            target: VPNPickerService
            function onVisibleChanged() {
                if (VPNPickerService.visible) {
                    win.isOpen = true;
                } else {
                    closeTimer.restart();
                    win.isOpen = false;
                }
            }
        }

        onIsOpenChanged: {
            if (isOpen) {
                pendingVpnName = "";
                pendingConnect = false;
                mouseActive = false;
                searchInput.text = "";
                selectedVpnName = filteredVPNs.length > 0 ? filteredVPNs[0].short_name : "";
                searchInput.forceActiveFocus();
            }
        }

        Connections {
            target: Network
            function onVpnGatewayChanged() {
                if (win.pendingVpnName)
                    win.pendingVpnName = "";
                if (win.pendingConnect && Network.vpnGateway.length > 0) {
                    win.pendingConnect = false;
                    autoCloseTimer.restart();
                }
            }
        }

        function isConnected(vpn) {
            const gw = Network.vpnGateway.toLowerCase();
            return gw.length > 0 && gw.includes(vpn.partial_gw_name.toLowerCase());
        }

        function navigate(delta) {
            mouseActive = false;
            const n = filteredVPNs.length;
            if (n === 0)
                return;
            const cur = currentIndex < 0 ? 0 : currentIndex;
            selectedVpnName = filteredVPNs[(cur + delta + n) % n].short_name;
        }

        function toggleSelected() {
            const vpn = filteredVPNs[currentIndex];
            if (!vpn || pendingVpnName)
                return;
            const connecting = !win.isConnected(vpn);
            if (connecting)
                UsageTracker.record("vpn:" + vpn.short_name);
            pendingVpnName = vpn.short_name;
            if (connecting)
                pendingConnect = true;
            toggleProcess.command = ["bash", "-c", vpn.toggler_path];
            toggleProcess.running = true;
        }

        function disconnectAll() {
            if (!Network.vpnConnected || !Settings.disconnectVpnsPath || pendingVpnName)
                return;
            pendingVpnName = "__all__";
            Quickshell.execDetached(["bash", "-c", Settings.disconnectVpnsPath]);
        }

        Process {
            id: toggleProcess
            onExited: win.pendingVpnName = ""
        }

        Timer {
            id: closeTimer
            interval: 220
            repeat: false
        }
        Timer {
            id: autoCloseTimer
            interval: 1000
            repeat: false
            onTriggered: VPNPickerService.dismiss()
        }

        Keys.onEscapePressed: VPNPickerService.dismiss()

        MouseArea {
            anchors.fill: parent
            enabled: win.isOpen
            onClicked: VPNPickerService.dismiss()
        }

        // ── Center panel ─────────────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.35)
            width: 500
            height: mainRect.height

            opacity: win.isOpen ? 1.0 : 0.0
            scale: win.isOpen ? 1.0 : 0.96
            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }
            HoverHandler {
                onPointChanged: win.mouseActive = true
            }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 12
                samples: 22
                color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.5)
            }

            Rectangle {
                id: mainRect
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: panelCol.implicitHeight + 24
                color: MatugenColors.md3.surface
                radius: Globals.componentRadius
                clip: true

                ColumnLayout {
                    id: panelCol
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 12
                    }
                    spacing: 8

                    // ── Search bar ───────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        color: MatugenColors.md3.surface_container
                        radius: Globals.componentRadius

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 14
                                rightMargin: 10
                            }
                            spacing: 10

                            Text {
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                color: MatugenColors.md3.on_surface
                                opacity: 0.5
                                text: "vpn_key"
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.pixelSize: 16
                                color: MatugenColors.md3.on_surface
                                selectionColor: MatugenColors.md3.primary
                                clip: true
                                onTextChanged: Qt.callLater(function () {
                                    const filtered = win.filteredVPNs;
                                    if (!filtered.some(v => v.short_name === win.selectedVpnName))
                                        win.selectedVpnName = filtered.length > 0 ? filtered[0].short_name : "";
                                })

                                Text {
                                    anchors.fill: parent
                                    text: Localization.t("vpnPicker.search", "Search VPNs...")
                                    font: searchInput.font
                                    color: MatugenColors.md3.on_surface
                                    opacity: 0.3
                                    visible: searchInput.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Keys.onEscapePressed: VPNPickerService.dismiss()
                                Keys.onUpPressed: win.navigate(-1)
                                Keys.onDownPressed: win.navigate(1)
                                Keys.onReturnPressed: win.toggleSelected()
                                Keys.onPressed: function (event) {
                                    if (event.modifiers & Qt.ControlModifier) {
                                        if (event.key === Qt.Key_N) {
                                            win.navigate(1);
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_P) {
                                            win.navigate(-1);
                                            event.accepted = true;
                                        } else if (event.nativeScanCode === Globals.scanCodes['D']) {
                                            win.disconnectAll();
                                            event.accepted = true;
                                        }
                                    }
                                }
                            }

                            // Ctrl+D badge — visible when any VPN is connected
                            Rectangle {
                                visible: Network.vpnConnected
                                implicitHeight: 28
                                implicitWidth: discRow.implicitWidth + 14
                                radius: Globals.componentRadius - 4
                                color: win.pendingVpnName === "__all__" ? ColorUtils.transparentize(MatugenColors.md3.error, 0.35) : ColorUtils.transparentize(MatugenColors.md3.error, 0.55)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                RowLayout {
                                    id: discRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        id: discSpinner
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 13
                                        font.variableAxes: ({
                                                "FILL": 1
                                            })
                                        renderType: Text.NativeRendering
                                        color: MatugenColors.md3.on_surface
                                        text: "progress_activity"
                                        visible: win.pendingVpnName === "__all__"
                                        NumberAnimation on rotation {
                                            from: 0
                                            to: 360
                                            duration: 900
                                            loops: Animation.Infinite
                                            running: discSpinner.visible
                                        }
                                    }
                                    Text {
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 13
                                        font.variableAxes: ({
                                                "FILL": 1
                                            })
                                        renderType: Text.NativeRendering
                                        color: MatugenColors.md3.on_surface
                                        text: "link_off"
                                        opacity: 0.85
                                        visible: win.pendingVpnName !== "__all__"
                                    }
                                    Text {
                                        text: "^D"
                                        font.pixelSize: 11
                                        color: MatugenColors.md3.on_surface
                                        opacity: 0.85
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        win.disconnectAll();
                                        searchInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }

                    // ── VPN list ─────────────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        clip: true
                        implicitHeight: Math.min(win.filteredVPNs.length, 8) * 46
                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }

                        ListView {
                            id: vpnList
                            anchors.fill: parent
                            clip: true
                            model: win.filteredVPNs
                            currentIndex: win.currentIndex
                            highlightMoveDuration: 0

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: vpnList.width
                                height: 46

                                readonly property bool connected: win.isConnected(modelData)
                                readonly property bool selected: index === win.currentIndex
                                readonly property bool pending: win.pendingVpnName === modelData.short_name

                                Rectangle {
                                    anchors {
                                        fill: parent
                                        leftMargin: 2
                                        rightMargin: 2
                                        topMargin: 1
                                        bottomMargin: 1
                                    }
                                    color: selected ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
                                    radius: Globals.componentRadius - 4
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 40
                                        }
                                    }

                                    RowLayout {
                                        anchors {
                                            fill: parent
                                            leftMargin: 12
                                            rightMargin: 12
                                        }
                                        spacing: 12

                                        // Spinner or lock icon
                                        Text {
                                            id: rowSpinner
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            font.variableAxes: ({
                                                    "FILL": 1
                                                })
                                            renderType: Text.NativeRendering
                                            color: MatugenColors.md3.primary
                                            text: "progress_activity"
                                            visible: pending
                                            NumberAnimation on rotation {
                                                from: 0
                                                to: 360
                                                duration: 900
                                                loops: Animation.Infinite
                                                running: rowSpinner.visible
                                            }
                                        }
                                        Text {
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            color: connected ? MatugenColors.md3.secondary : MatugenColors.md3.on_surface
                                            opacity: connected ? 0.9 : 0.35
                                            text: connected ? "vpn_key" : "vpn_key_off"
                                            visible: !pending
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                }
                                            }
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                }
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.short_name
                                            font.pixelSize: 15
                                            color: MatugenColors.md3.on_surface
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: pending ? Localization.t("vpnPicker.status.connecting", "Connecting...") : connected ? Network.vpnGateway : Localization.t("vpnPicker.status.disconnected", "Disconnected")
                                            font.pixelSize: 12
                                            color: pending ? MatugenColors.md3.primary : connected ? MatugenColors.md3.secondary : MatugenColors.md3.on_surface
                                            opacity: pending ? 0.9 : connected ? 0.7 : 0.35
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: 180
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                }
                                            }
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            if (win.mouseActive)
                                                win.selectedVpnName = modelData.short_name;
                                        }
                                        onClicked: {
                                            win.selectedVpnName = modelData.short_name;
                                            win.toggleSelected();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Empty state ──────────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        readonly property bool shouldShow: win.filteredVPNs.length === 0
                        visible: shouldShow
                        implicitHeight: shouldShow ? 44 : 0
                        clip: true
                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: Settings.vpns.length === 0 ? Localization.t("vpnPicker.empty.notConfigured", "No VPNs configured in settings.json") : Localization.t("common.noMatches", "No matches")
                            font.pixelSize: 13
                            color: MatugenColors.md3.on_surface
                            opacity: 0.35
                        }
                    }
                }
            }
        }
    }
}
