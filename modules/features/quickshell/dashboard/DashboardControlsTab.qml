import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.services
import qs.utils

Item {
    id: root
    required property var win

    property alias contentImplicitHeight: tab0Col.implicitHeight
    property alias outputDropdown: _outputDropdown
    property alias inputDropdown: _inputDropdown
    property alias btDevList: _btDevList
    property alias btCombinedModel: _btCombinedModel
    property alias vpnListRepeater: _vpnListRepeater

    function compareLabels(a, b) {
        const left = String(a ?? "").toLowerCase();
        const right = String(b ?? "").toLowerCase();
        if (left < right)
            return -1;
        if (left > right)
            return 1;
        return 0;
    }

    function sortedByLabel(items, labelFn) {
        const sorted = items.slice();
        sorted.sort((a, b) => compareLabels(labelFn(a), labelFn(b)));
        return sorted;
    }

    function audioNodeLabel(node) {
        return node?.nickname || node?.description || node?.name || "";
    }

    function bluetoothDeviceLabel(device) {
        return device?.name || "";
    }

    function vpnLabel(vpn) {
        return vpn?.short_name || vpn?.partial_gw_name || vpn?.toggler_path || "";
    }

    // ── Shared sub-components ─────────────────────────────────────────────────

    component SectionDivider: Rectangle {
        Layout.fillWidth: true
        height: 1
        color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.92)
        Layout.topMargin: 7
        Layout.bottomMargin: 7
    }

    component AudioVolumeRow: RowLayout {
        id: avr
        property PwNode node
        property bool isSink: true
        property bool kbFocused: false
        property bool showHints: false
        Layout.bottomMargin: 6
        spacing: 10

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 6
            color: avr.node?.audio?.muted
                ? ColorUtils.transparentize(MatugenColors.md3.error, 0.55)
                : muteMouse.containsMouse
                    ? MatugenColors.md3.surface_container_highest
                    : MatugenColors.md3.surface_container
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
            Text {
                anchors.centerIn: parent
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                color: MatugenColors.md3.on_surface
                font.variableAxes: ({
                        "FILL": 1
                    })
                renderType: Text.NativeRendering
                text: avr.node?.audio?.muted ? (avr.isSink ? "volume_off" : "mic_off") : (avr.isSink ? "volume_up" : "\ue029")
            }
            MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (avr.node?.audio)
                        avr.node.audio.muted = !avr.node.audio.muted;
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: -3
                anchors.rightMargin: -3
                opacity: avr.showHints ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }
                width: 16
                height: 16
                radius: 3
                z: 1
                color: MatugenColors.md3.primary
                Text {
                    anchors.centerIn: parent
                    text: "M"
                    font.pixelSize: 9
                    font.bold: true
                    color: MatugenColors.md3.on_primary
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 30
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: avr.kbFocused ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.82) : ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.88)
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Rectangle {
                    width: parent.width * Math.min(1, avr.node?.audio?.volume ?? 0)
                    height: parent.height
                    radius: parent.radius
                    color: avr.node?.audio?.muted ? ColorUtils.transparentize(MatugenColors.md3.error, 0.5) : MatugenColors.md3.primary
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }
            }
            Rectangle {
                x: Math.min(1, avr.node?.audio?.volume ?? 0) * (parent.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: avr.kbFocused ? 20 : 14
                height: width
                radius: width / 2
                color: avr.kbFocused ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if (avr.node?.audio)
                        avr.node.audio.volume = Math.max(0, Math.min(1.0, mouseX / width));
                }
                onPositionChanged: {
                    if (pressed && avr.node?.audio)
                        avr.node.audio.volume = Math.max(0, Math.min(1.0, mouseX / width));
                }
            }
        }

        Text {
            text: Math.round((avr.node?.audio?.volume ?? 0) * 100) + "%"
            font.pixelSize: 15
            color: MatugenColors.md3.on_surface
            opacity: 0.6
            Layout.preferredWidth: 42
            horizontalAlignment: Text.AlignRight
        }
    }

    component DeviceDropdown: Item {
        id: dd
        property var nodes: []
        property var activeNode: null
        property bool expanded: false
        property int focusedIndex: -1
        property bool showHints: false
        signal selected(var node)

        Layout.fillWidth: true
        Layout.bottomMargin: 6
        implicitHeight: 32
        visible: nodes.length > 0
        z: expanded ? 10 : 0

        Rectangle {
            id: ddHeaderRect
            width: parent.width
            height: 32
            radius: 6
            color: ddHeader.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.25) : ColorUtils.transparentize(MatugenColors.md3.secondary_container, 0.72)
            border.width: 1
            border.color: dd.expanded ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.55) : ColorUtils.transparentize(MatugenColors.md3.outline, 0.72)
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: dd.activeNode ? (dd.activeNode.nickname || dd.activeNode.description || dd.activeNode.name) : Localization.t("dashboard.controls.audio.none", "None")
                    font.pixelSize: 15
                    color: MatugenColors.md3.on_surface
                    opacity: 0.85
                    elide: Text.ElideRight
                }
                Text {
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 14
                    font.variableAxes: ({
                            "FILL": 1
                        })
                    renderType: Text.NativeRendering
                    color: MatugenColors.md3.on_surface
                    opacity: 0.45
                    text: dd.expanded ? "keyboard_arrow_up" : "keyboard_arrow_down"
                }
            }
            MouseArea {
                id: ddHeader
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dd.expanded = !dd.expanded
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 9
                opacity: dd.showHints ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }
                width: 16
                height: 16
                radius: 3
                z: 1
                color: MatugenColors.md3.primary
                Text {
                    anchors.centerIn: parent
                    text: "C"
                    font.pixelSize: 9
                    font.bold: true
                    color: MatugenColors.md3.on_primary
                }
            }
        }

        Rectangle {
            x: 0
            y: ddHeaderRect.height + 2
            width: parent.width
            visible: opacity > 0
            opacity: dd.expanded ? 1.0 : 0.0
            scale: dd.expanded ? 1.0 : 0.97
            transformOrigin: Item.Top
            implicitHeight: floatCol.implicitHeight + 4
            radius: 6
            color: MatugenColors.md3.surface
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            border.color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.88)
            border.width: 1

            ColumnLayout {
                id: floatCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 2
                }
                spacing: 2

                Repeater {
                    model: dd.nodes
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool active: modelData === dd.activeNode
                        readonly property bool kbFocus: index === dd.focusedIndex
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 5
                        color: active ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.45) : kbFocus ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.25) : (ddItem.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.35) : ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.65))
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                        Text {
                            anchors {
                                left: parent.left
                                right: checkMark.left
                                verticalCenter: parent.verticalCenter
                            }
                            anchors.leftMargin: 12
                            anchors.rightMargin: 6
                            text: modelData.nickname || modelData.description || modelData.name
                            font.pixelSize: 14
                            color: MatugenColors.md3.on_surface
                            opacity: active ? 1.0 : 0.65
                            elide: Text.ElideRight
                        }
                        Text {
                            id: checkMark
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 10
                            visible: active
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                            font.variableAxes: ({
                                    "FILL": 1
                                })
                            renderType: Text.NativeRendering
                            color: MatugenColors.md3.primary
                            text: "done"
                        }
                        MouseArea {
                            id: ddItem
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dd.selected(modelData);
                                dd.expanded = false;
                            }
                        }
                    }
                }
            }
        }
    }

    component BtDeviceRow: Item {
        id: bdr
        property var device
        property bool kbFocused: false
        Layout.topMargin: 1
        Layout.bottomMargin: 1
        implicitHeight: btRowContent.implicitHeight + 10

        readonly property bool isConnected: device?.connected ?? false
        readonly property bool isPaired: (device?.paired ?? false) || (device?.trusted ?? false)
        readonly property bool isTransitioning: {
            const s = device?.state;
            return s === BluetoothDeviceState.Connecting || s === BluetoothDeviceState.Disconnecting;
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: bdr.kbFocused ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.22) : btRowHover.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.88) : ColorUtils.transparentize(MatugenColors.md3.on_surface, 1.0)
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        RowLayout {
            id: btRowContent
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 10

            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                Layout.alignment: Qt.AlignVCenter
                color: bdr.isConnected ? MatugenColors.md3.secondary : bdr.isPaired ? ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.6) : ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.88)
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
            Text {
                text: bdr.device?.name ?? Localization.t("dashboard.controls.bluetooth.unknownDevice", "Unknown")
                font.pixelSize: 15
                color: MatugenColors.md3.on_surface
                opacity: bdr.isConnected ? 0.90 : bdr.isPaired ? 0.55 : 0.45
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                visible: bdr.isTransitioning
                font.family: "Material Symbols Rounded"
                font.variableAxes: ({
                        "FILL": 1
                    })
                renderType: Text.NativeRendering
                font.pixelSize: 15
                color: MatugenColors.md3.on_surface
                opacity: 0.5
                text: "autorenew"
                RotationAnimator on rotation {
                    running: bdr.isTransitioning
                    from: 0
                    to: 360
                    duration: 1200
                    loops: Animation.Infinite
                }
            }
            Text {
                visible: !bdr.isTransitioning
                text: bdr.isConnected
                    ? Localization.t("dashboard.controls.bluetooth.status.connected", "Connected")
                    : bdr.isPaired
                        ? Localization.t("dashboard.controls.bluetooth.status.paired", "Paired")
                        : Localization.t("dashboard.controls.bluetooth.status.nearby", "Nearby")
                font.pixelSize: 12
                color: MatugenColors.md3.on_surface
                opacity: 0.40
            }
        }

        MouseArea {
            id: btRowHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (bdr.isTransitioning)
                    return;
                if (bdr.isConnected)
                    bdr.device.disconnect();
                else
                    bdr.device.connect();
            }
        }
    }

    component StatRow: RowLayout {
        id: sr
        property string icon: ""
        property string label: ""
        property real value: 0
        property string displayLabel: ""
        property color accentColor: MatugenColors.md3.primary

        Layout.fillWidth: true
        Layout.topMargin: 3
        Layout.bottomMargin: 3
        spacing: 10

        Text {
            font.family: "Material Symbols Rounded"
            font.variableAxes: ({
                    "FILL": 1
                })
            renderType: Text.NativeRendering
            font.pixelSize: 16
            color: sr.accentColor
            opacity: 0.80
            text: sr.icon
            Behavior on color {
                ColorAnimation {
                    duration: 300
                }
            }
        }

        Text {
            text: sr.label
            font.pixelSize: 13
            color: MatugenColors.md3.on_surface
            opacity: 0.45
            Layout.preferredWidth: 30
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 4

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.90)

                Rectangle {
                    property real ratio: Math.min(1, sr.value / 100)
                    Behavior on ratio {
                        NumberAnimation {
                            duration: 600
                            easing.type: Easing.OutCubic
                        }
                    }
                    width: parent.width * ratio
                    height: parent.height
                    radius: parent.radius
                    color: sr.accentColor
                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                }
            }
        }

        Text {
            text: sr.displayLabel
            font.pixelSize: 13
            color: MatugenColors.md3.on_surface
            opacity: 0.65
            Layout.preferredWidth: 46
            horizontalAlignment: Text.AlignRight
        }
    }

    // ── Tab content ───────────────────────────────────────────────────────────

    Flickable {
        id: tabFlickable
        anchors.fill: parent
        anchors.margins: 12
        contentHeight: tab0Col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: tab0Col
            width: parent.width
            spacing: 0

            // ── Output ────────────────────────────────────────────────────────
            DashboardSection {
                win: root.win
                icon: "volume_up"
                label: Localization.t("dashboard.controls.sections.output", "Output")
                hintKey: "O"
                z: _outputDropdown.expanded ? 100 : 0
                AudioVolumeRow {
                    Layout.fillWidth: true
                    node: Audio.sink
                    isSink: true
                    kbFocused: root.win.outputFocused && root.win.outputDeviceIdx < 0
                    showHints: root.win.outputHintMode
                }
                DeviceDropdown {
                    id: _outputDropdown
                    nodes: {
                        const r = [];
                        for (const n of Pipewire.nodes.values)
                            if (n.audio && !n.isStream && n.isSink)
                                r.push(n);
                        return root.sortedByLabel(r, root.audioNodeLabel);
                    }
                    activeNode: Pipewire.defaultAudioSink
                    focusedIndex: root.win.outputDeviceIdx
                    showHints: root.win.outputHintMode
                    onSelected: node => {
                        Pipewire.preferredDefaultAudioSink = node;
                    }
                }
            }

            SectionDivider {}

            // ── Input ─────────────────────────────────────────────────────────
            DashboardSection {
                win: root.win
                icon: "\ue029"
                label: Localization.t("dashboard.controls.sections.input", "Input")
                hintKey: "I"
                z: _inputDropdown.expanded ? 100 : 0
                AudioVolumeRow {
                    Layout.fillWidth: true
                    node: Audio.source
                    isSink: false
                    kbFocused: root.win.inputFocused && root.win.inputDeviceIdx < 0
                    showHints: root.win.inputHintMode
                }
                DeviceDropdown {
                    id: _inputDropdown
                    nodes: {
                        const r = [];
                        for (const n of Pipewire.nodes.values)
                            if (n.audio && !n.isStream && !n.isSink)
                                r.push(n);
                        return root.sortedByLabel(r, root.audioNodeLabel);
                    }
                    activeNode: Pipewire.defaultAudioSource
                    focusedIndex: root.win.inputDeviceIdx
                    showHints: root.win.inputHintMode
                    onSelected: node => {
                        Pipewire.preferredDefaultAudioSource = node;
                    }
                }
            }

            SectionDivider {}

            // ── Bluetooth ─────────────────────────────────────────────────────
            DashboardSection {
                win: root.win
                icon: "bluetooth"
                label: Localization.t("dashboard.controls.sections.bluetooth", "Bluetooth")
                z: btExpandedList.curtainHeight > 22 ? 100 : 0
                button: Component {
                    Rectangle {
                        implicitWidth: scanRow.implicitWidth + 18
                        implicitHeight: 24
                        radius: 5
                        color: (root.win.adapter?.discovering)
                            ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.45)
                            : scanMouse.containsMouse
                                ? MatugenColors.md3.surface_container_highest
                                : MatugenColors.md3.surface_container
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        RowLayout {
                            id: scanRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 13
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                color: MatugenColors.md3.on_surface
                                opacity: (root.win.adapter?.discovering) ? 1.0 : 0.55
                                text: "refresh"
                                RotationAnimator on rotation {
                                    running: root.win.adapter?.discovering ?? false
                                    from: 0
                                    to: 360
                                    duration: 1400
                                    loops: Animation.Infinite
                                }
                            }
                            Text {
                                text: (root.win.adapter?.discovering)
                                    ? Localization.t("dashboard.controls.bluetooth.scanning", "Scanning...")
                                    : Localization.t("dashboard.controls.bluetooth.scan", "Scan")
                                font.pixelSize: 14
                                color: MatugenColors.md3.on_surface
                                opacity: (root.win.adapter?.discovering) ? 0.9 : 0.55
                            }
                        }
                        MouseArea {
                            id: scanMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.win.adapter)
                                    return;

                                const shouldDiscover = !root.win.adapter.discovering;
                                root.win.adapter.discovering = shouldDiscover;
                                if (shouldDiscover) {
                                    root.win.btExpanded = true;
                                    Qt.callLater(() => btExpandedList.rebuildDeviceModel());
                                }
                            }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.bottomMargin: -3
                            anchors.rightMargin: 3
                            opacity: root.win.btHintMode ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                            width: 16
                            height: 16
                            radius: 3
                            z: 1
                            color: MatugenColors.md3.primary
                            Text {
                                anchors.centerIn: parent
                                text: "S"
                                font.pixelSize: 9
                                font.bold: true
                                color: MatugenColors.md3.on_primary
                            }
                        }
                    }
                }

                Repeater {
                    model: root.win.btConnectedDevices
                    delegate: BtDeviceRow {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        device: modelData
                        kbFocused: root.win.btFocused && root.win.btFocusIdx === index
                    }
                }

                Item {
                    id: btExpandedList
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    // implicitHeight: btExpandedList.curtainHeight
                    z: 100
                    property int pairedCount: 0
                    property real availableHeight: {
                        // depend on scroll/layout changes
                        const _ = tabFlickable.contentY + tab0Col.implicitHeight + btExpandedList.y;
                        const pos = btExpandedList.mapToItem(tabFlickable, 0, 0);
                        return Math.max(22, tabFlickable.height - pos.y);
                    }
                    property real curtainHeight: root.win.btExpanded ? availableHeight : (root.win.btHiddenCount > 0 ? 22 : 0)
                    Behavior on curtainHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    ListModel {
                        id: _btCombinedModel
                    }

                    function rebuildDeviceModel() {
                        _btCombinedModel.clear();
                        const paired = root.sortedByLabel(root.win.btAllDevices.filter(d => !d.connected && (d.paired || d.trusted)), root.bluetoothDeviceLabel);
                        for (const d of paired)
                            _btCombinedModel.append({
                                btDevice: d
                            });
                        pairedCount = paired.length;

                        if (!(root.win.adapter?.discovering ?? false))
                            return;

                        const nearby = root.win.btAllDevices.filter(d => !d.connected && !d.paired && !d.trusted);
                        for (const d of nearby)
                            _btCombinedModel.append({
                                btDevice: d
                            });
                    }

                    function appendNewDiscovered() {
                        const before = _btCombinedModel.count;
                        const listed = new Set();
                        for (let i = 0; i < _btCombinedModel.count; i++)
                            listed.add(_btCombinedModel.get(i).btDevice.name);
                        const nearby = root.win.btAllDevices.filter(d => !d.connected && !d.paired && !d.trusted);
                        for (const d of nearby)
                            if (!listed.has(d.name))
                                _btCombinedModel.append({
                                    btDevice: d
                                });
                        const discovered = _btCombinedModel.count - btExpandedList.pairedCount;
                        if (_btCombinedModel.count > before && discovered > 0 && discovered <= 4)
                            Qt.callLater(() => _btDevList.scrollToIndex(btExpandedList.pairedCount, true));
                    }

                    Connections {
                        target: root.win
                        function onBtExpandedChanged() {
                            if (root.win.btExpanded)
                                btExpandedList.rebuildDeviceModel();
                        }
                        function onBtConnectedDevicesChanged() {
                            if (root.win.btExpanded)
                                btExpandedList.rebuildDeviceModel();
                        }
                        function onBtAllDevicesChanged() {
                            if (!(root.win.adapter?.discovering ?? false))
                                return;
                            if (!root.win.btExpanded)
                                return;
                            btExpandedList.appendNewDiscovered();
                        }
                        function onBtFocusIdxChanged() {
                            if (!root.win.btExpanded)
                                return;
                            const idx = root.win.btFocusIdx - root.win.btConnectedDevices.length;
                            if (idx >= 0 && idx < _btCombinedModel.count)
                                Qt.callLater(() => _btDevList.scrollToIndex(idx, false));
                        }
                    }

                    Rectangle {
                        visible: btExpandedList.curtainHeight > 22
                        width: parent.width
                        height: btExpandedList.curtainHeight - 22
                        clip: true
                        color: MatugenColors.md3.surface_container_high

                        // Swallow stray clicks/wheel/hover so they don't fall through to items behind the curtain
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onWheel: function(wheel) { wheel.accepted = true }
                        }

                        Flickable {
                            id: _btDevList
                            anchors {
                                left: parent.left
                                right: btScrollBar.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            anchors.margins: 4
                            anchors.rightMargin: 8
                            contentHeight: _btCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            function scrollToIndex(idx, alignTop) {
                                const item = _btDevListRepeater.itemAt(idx);
                                if (!item) return;
                                const iy = item.y;
                                const ih = item.height;
                                if (alignTop) _btDevList.contentY = iy;
                                else if (iy < _btDevList.contentY) _btDevList.contentY = iy;
                                else if (iy + ih > _btDevList.contentY + _btDevList.height) _btDevList.contentY = iy + ih - _btDevList.height;
                            }

                            ColumnLayout {
                                id: _btCol
                                width: _btDevList.width
                                spacing: 0

                                Repeater {
                                    id: _btDevListRepeater
                                    model: _btCombinedModel
                                    delegate: Item {
                                        required property var model
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: _row.implicitHeight
                                        property var btDevice: model.btDevice
                                        BtDeviceRow {
                                            id: _row
                                            width: parent.width
                                            device: parent.btDevice
                                            kbFocused: root.win.btFocused && root.win.btFocusIdx === (root.win.btConnectedDevices.length + index)
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: btScrollBar
                            anchors {
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                            }
                            anchors.margins: 2
                            width: 3
                            radius: 2
                            color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.85)
                            visible: _btDevList.contentHeight > _btDevList.height + 1 && btExpandedList.curtainHeight >= btExpandedList.availableHeight - 1

                            Rectangle {
                                width: parent.width
                                radius: parent.radius
                                color: MatugenColors.md3.on_surface
                                opacity: 0.6
                                height: _btDevList.contentHeight > 0 ? Math.max(16, parent.height * _btDevList.height / _btDevList.contentHeight) : 0
                                y: _btDevList.contentHeight > _btDevList.height ? (parent.height - height) * _btDevList.contentY / (_btDevList.contentHeight - _btDevList.height) : 0
                            }
                        }
                    }

                    Item {
                        id: btExpandToggle
                        width: parent.width
                        height: 22
                        y: btExpandedList.curtainHeight - 22
                        z: 10
                        Rectangle {
                            anchors.fill: parent
                            color: MatugenColors.md3.surface_container_high
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 1
                            color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.9)
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 18
                            radius: 4
                            color: MatugenColors.md3.surface_container_high
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Rounded"
                                font.variableAxes: ({ "FILL": 1 })
                                renderType: Text.NativeRendering
                                font.pixelSize: 15
                                color: MatugenColors.md3.on_surface
                                opacity: expandToggleMouse.containsMouse ? 0.7 : 0.4
                                text: root.win.btExpanded ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }
                        }
                        MouseArea {
                            id: expandToggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.win.btExpanded = !root.win.btExpanded
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 8
                            width: 16; height: 16; radius: 3; z: 2
                            color: MatugenColors.md3.primary
                            opacity: root.win.tabHintMode ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: "B"
                                font.pixelSize: 9; font.bold: true
                                color: MatugenColors.md3.on_primary
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.win.btAllDevices.length === 0
                    text: Localization.t("dashboard.controls.bluetooth.noDevices", "No devices")
                    font.pixelSize: 15
                    color: MatugenColors.md3.on_surface
                    opacity: 0.3
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            SectionDivider {}

            // ── Network ───────────────────────────────────────────────────────
            DashboardSection {
                win: root.win
                icon: "wifi"
                label: Localization.t("dashboard.controls.sections.network", "Network")
                z: vpnExpandedList.curtainHeight > 22 ? 100 : 0
                enabled: !root.win.btExpanded
                button: Component {
                    Rectangle {
                        id: wifiToggle
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 6
                        color: Network.wifiEnabled
                            ? ColorUtils.transparentize(MatugenColors.md3.primary, wifiToggleMouse.containsMouse ? 0.48 : 0.62)
                            : wifiToggleMouse.containsMouse
                                ? MatugenColors.md3.surface_container_highest
                                : MatugenColors.md3.surface_container
                        border.width: Network.wifiEnabled ? 0 : 1
                        border.color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.72)
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Network.wifiEnabled ? "wifi" : "wifi_off"
                            font.family: "Material Symbols Rounded"
                            font.variableAxes: ({
                                    "FILL": Network.wifiEnabled ? 1 : 0
                                })
                            renderType: Text.NativeRendering
                            font.pixelSize: 16
                            color: Network.wifiEnabled ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                            opacity: Network.wifiEnabled ? 1.0 : 0.55
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                        }

                        MouseArea {
                            id: wifiToggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Network.setWifiEnabled(!Network.wifiEnabled)
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.bottomMargin: -3
                            anchors.rightMargin: 1
                            opacity: root.win.tabHintMode ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                            width: 16
                            height: 16
                            radius: 3
                            z: 1
                            color: MatugenColors.md3.primary
                            Text {
                                anchors.centerIn: parent
                                text: "W"
                                font.pixelSize: 9
                                font.bold: true
                                color: MatugenColors.md3.on_primary
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: netCol.implicitHeight + 20
                    readonly property bool connected: Network.wifi || Network.ethernet

                    ColumnLayout {
                        id: netCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: 10
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            Text {
                                text: Network.materialSymbol
                                font.family: "Material Symbols Rounded"
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                font.pixelSize: 38
                                color: Network.ethernet ? MatugenColors.md3.secondary : Network.wifi ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                                opacity: parent.parent.parent.connected ? 1.0 : 0.25
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 300
                                    }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: {
                                        if (Network.ethernet)
                                            return Network.ethernetName || Localization.t("dashboard.controls.network.ethernet", "Ethernet");
                                        if (Network.wifiSsid)
                                            return Network.wifiSsid;
                                        if (Network.networkName && Network.networkName !== "lo")
                                            return Network.networkName;
                                        return Localization.t("dashboard.controls.network.notConnected", "Not connected");
                                    }
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    color: MatugenColors.md3.on_surface
                                    opacity: parent.parent.parent.parent.connected ? 0.90 : 0.30
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 300
                                        }
                                    }
                                }
                                RowLayout {
                                    spacing: 10
                                    Rectangle {
                                        implicitWidth: netTypeLbl.implicitWidth + 14
                                        implicitHeight: 20
                                        radius: 5
                                        color: Network.ethernet ? ColorUtils.transparentize(MatugenColors.md3.secondary, 0.55) : Network.wifi ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.55) : ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.88)
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 300
                                            }
                                        }
                                        Text {
                                            id: netTypeLbl
                                            anchors.centerIn: parent
                                            text: Network.ethernet
                                                ? Localization.t("dashboard.controls.network.ethernet", "Ethernet")
                                                : Network.wifi
                                                    ? Localization.t("dashboard.controls.network.wifi", "Wi-Fi")
                                                    : Localization.t("dashboard.controls.network.offline", "Offline")
                                            font.pixelSize: 11
                                            color: MatugenColors.md3.on_surface
                                            opacity: 0.80
                                        }
                                    }
                                }
                            }
                        }

                        // ── VPN ───────────────────────────────────────────────────
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: vpnSummaryRow.implicitHeight
                            visible: Settings.vpns.length > 0
                            RowLayout {
                                id: vpnSummaryRow
                                width: parent.width
                                spacing: 8
                                Text {
                                    text: "vpn_key"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    font.variableAxes: ({
                                            "FILL": 1
                                        })
                                    renderType: Text.NativeRendering
                                    color: Network.vpnConnected ? MatugenColors.md3.secondary : MatugenColors.md3.on_surface
                                    opacity: Network.vpnConnected ? 0.90 : 0.35
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 300
                                        }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 300
                                        }
                                    }
                                }
                                Text {
                                    text: root.win.connectedVpn ? root.win.connectedVpn.short_name : Localization.t("dashboard.controls.network.vpn", "VPN")
                                    font.pixelSize: 13
                                    color: MatugenColors.md3.on_surface
                                    opacity: Network.vpnConnected ? 0.85 : 0.40
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 300
                                        }
                                    }
                                }
                                Text {
                                    visible: Network.vpnConnected
                                    text: Network.vpnGateway
                                    font.pixelSize: 11
                                    color: MatugenColors.md3.secondary
                                    opacity: 0.55
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Item {
                                    Layout.fillWidth: true
                                    visible: !Network.vpnConnected
                                }
                                Rectangle {
                                    visible: Network.vpnConnected
                                    implicitWidth: vpnCompactDiscLbl.implicitWidth + 14
                                    implicitHeight: 20
                                    radius: 5
                                    color: vpnCompactDiscArea.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.error, 0.3) : ColorUtils.transparentize(MatugenColors.md3.error, 0.55)
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                    Text {
                                        id: vpnCompactDiscLbl
                                        anchors.centerIn: parent
                                        text: Localization.t("dashboard.controls.network.disconnect", "Disconnect")
                                        font.pixelSize: 11
                                        color: MatugenColors.md3.on_surface
                                        opacity: 0.85
                                    }
                                    MouseArea {
                                        id: vpnCompactDiscArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(["bash", "-c", Settings.disconnectVpnsPath])
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.right: parent.right
                                        anchors.bottomMargin: -3
                                        anchors.rightMargin: -6
                                        opacity: root.win.tabHintMode ? 1.0 : 0.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 120
                                            }
                                        }
                                        width: 16
                                        height: 16
                                        radius: 3
                                        z: 1
                                        color: MatugenColors.md3.primary
                                        Text {
                                            anchors.centerIn: parent
                                            text: "D"
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: MatugenColors.md3.on_primary
                                        }
                                    }
                                }
                            }
                        }

                    }
                }

                Item {
                    id: vpnExpandedList
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    // implicitHeight: vpnExpandedList.curtainHeight
                    z: 100
                    property real availableHeight: {
                        const _ = tabFlickable.contentY + tab0Col.implicitHeight + vpnExpandedList.y;
                        const pos = vpnExpandedList.mapToItem(tabFlickable, 0, 0);
                        return Math.max(22, tabFlickable.height - pos.y);
                    }
                    property real curtainHeight: root.win.vpnExpanded ? availableHeight : (Settings.vpns.length > 0 ? 22 : 0)
                    Behavior on curtainHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    property var activeVpnList: []

                    Connections {
                        target: root.win
                        function onVpnExpandedChanged() {
                            if (root.win.vpnExpanded)
                                vpnExpandedList.activeVpnList = root.sortedByLabel(Settings.vpns.filter(v => v !== root.win.connectedVpn), root.vpnLabel);
                        }
                        function onConnectedVpnChanged() {
                            if (root.win.vpnExpanded)
                                vpnExpandedList.activeVpnList = root.sortedByLabel(Settings.vpns.filter(v => v !== root.win.connectedVpn), root.vpnLabel);
                        }
                        function onVpnFocusIdxChanged() {
                            if (!root.win.vpnExpanded)
                                return;
                            const idx = root.win.vpnFocusIdx;
                            if (idx < 0 || idx >= _vpnListRepeater.count)
                                return;
                            Qt.callLater(() => {
                                const item = _vpnListRepeater.itemAt(idx);
                                if (!item)
                                    return;
                                const iy = item.y;
                                const ih = item.height;
                                if (iy < _vpnFlickable.contentY)
                                    _vpnFlickable.contentY = iy;
                                else if (iy + ih > _vpnFlickable.contentY + _vpnFlickable.height)
                                    _vpnFlickable.contentY = iy + ih - _vpnFlickable.height;
                            });
                        }
                    }

                    Rectangle {
                        visible: vpnExpandedList.curtainHeight > 22
                        width: parent.width
                        height: vpnExpandedList.curtainHeight - 22
                        clip: true
                        color: MatugenColors.md3.surface_container_high

                        // Swallow stray clicks/wheel/hover so they don't fall through to items behind the curtain
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onWheel: function(wheel) { wheel.accepted = true }
                        }

                        Flickable {
                            id: _vpnFlickable
                            anchors {
                                left: parent.left
                                right: vpnScrollBar.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            anchors.margins: 4
                            anchors.rightMargin: 8
                            contentHeight: _vpnCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: _vpnCol
                                width: _vpnFlickable.width
                                spacing: 0

                                Repeater {
                                    id: _vpnListRepeater
                                    model: vpnExpandedList.activeVpnList
                                    delegate: Item {
                                        id: vpnEntry
                                        required property var modelData
                                        required property int index

                                        function toggle() {
                                            if (vpnEntry.toggling)
                                                return;
                                            vpnEntry.toggling = true;
                                            vpnToggle.running = true;
                                        }
                                        Layout.fillWidth: true
                                        implicitHeight: vpnRowLayout.implicitHeight + 8

                                        readonly property bool isConnected: {
                                            const gw = Network.vpnGateway.toLowerCase();
                                            const p = vpnEntry.modelData.partial_gw_name.toLowerCase();
                                            return gw.length > 0 && gw.includes(p);
                                        }
                                        property bool toggling: false

                                        Process {
                                            id: vpnToggle
                                            command: ["bash", "-c", vpnEntry.modelData.toggler_path]
                                            onExited: vpnEntry.toggling = false
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 5
                                            color: (root.win.vpnFocused && root.win.vpnFocusIdx === vpnEntry.index) ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.22) : vpnRowMouse.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.88) : ColorUtils.transparentize(MatugenColors.md3.on_surface, 1.0)
                                            Behavior on color {
                                                ColorAnimation { duration: 100 }
                                            }
                                        }

                                        RowLayout {
                                            id: vpnRowLayout
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                            }
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 10
                                            SequentialAnimation on opacity {
                                                running: vpnEntry.toggling
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                                            }
                                            onVisibleChanged: if (!vpnEntry.toggling)
                                                opacity = 1.0

                                            Rectangle {
                                                width: 8
                                                height: 8
                                                radius: 4
                                                Layout.alignment: Qt.AlignVCenter
                                                color: vpnEntry.isConnected ? MatugenColors.md3.secondary : ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.72)
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                            Text {
                                                text: vpnEntry.modelData.short_name
                                                font.pixelSize: 15
                                                color: MatugenColors.md3.on_surface
                                                opacity: vpnEntry.isConnected ? 0.90 : 0.45
                                                Behavior on opacity { NumberAnimation { duration: 300 } }
                                            }
                                            Item {
                                                Layout.fillWidth: true
                                                implicitHeight: 1
                                                Text {
                                                    visible: vpnEntry.isConnected
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: Network.vpnGateway
                                                    font.pixelSize: 12
                                                    color: MatugenColors.md3.secondary
                                                    opacity: 0.40
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }
                                            }
                                            Text {
                                                visible: vpnEntry.toggling
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 16
                                                font.variableAxes: ({ "FILL": 1 })
                                                renderType: Text.NativeRendering
                                                color: MatugenColors.md3.primary
                                                text: "autorenew"
                                                RotationAnimator on rotation {
                                                    running: vpnEntry.toggling
                                                    from: 0; to: 360
                                                    duration: 1200
                                                    loops: Animation.Infinite
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: vpnRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !vpnEntry.toggling
                                            onClicked: vpnEntry.toggle()
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: vpnScrollBar
                            anchors {
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                            }
                            anchors.margins: 2
                            width: 3
                            radius: 2
                            color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.85)
                            visible: _vpnFlickable.contentHeight > _vpnFlickable.height + 1 && vpnExpandedList.curtainHeight >= vpnExpandedList.availableHeight - 1

                            Rectangle {
                                width: parent.width
                                radius: parent.radius
                                color: MatugenColors.md3.on_surface
                                opacity: 0.6
                                height: _vpnFlickable.contentHeight > 0 ? Math.max(16, parent.height * _vpnFlickable.height / _vpnFlickable.contentHeight) : 0
                                y: _vpnFlickable.contentHeight > _vpnFlickable.height ? (parent.height - height) * _vpnFlickable.contentY / (_vpnFlickable.contentHeight - _vpnFlickable.height) : 0
                            }
                        }
                    }

                    Item {
                        id: vpnExpandToggle
                        width: parent.width
                        height: 22
                        y: vpnExpandedList.curtainHeight - 22
                        z: 10
                        Rectangle {
                            anchors.fill: parent
                            color: MatugenColors.md3.surface_container_high
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 1
                            color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.9)
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 18
                            radius: 4
                            color: MatugenColors.md3.surface_container_high
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Rounded"
                                font.variableAxes: ({ "FILL": 1 })
                                renderType: Text.NativeRendering
                                font.pixelSize: 15
                                color: MatugenColors.md3.on_surface
                                opacity: vpnToggleMouse.containsMouse ? 0.7 : 0.4
                                text: root.win.vpnExpanded ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }
                        }
                        MouseArea {
                            id: vpnToggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.win.vpnExpanded = !root.win.vpnExpanded
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 8
                            width: 16; height: 16; radius: 3; z: 2
                            color: MatugenColors.md3.primary
                            opacity: root.win.tabHintMode ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: "V"
                                font.pixelSize: 9; font.bold: true
                                color: MatugenColors.md3.on_primary
                            }
                        }
                    }
                }
            }

            SectionDivider {}

            // ── Resources ─────────────────────────────────────────────────────
            DashboardSection {
                win: root.win
                icon: "memory"
                label: Localization.t("dashboard.controls.sections.resources", "Resources")
                StatRow {
                    icon: "developer_board"
                    label: Localization.t("dashboard.controls.resources.cpu", "CPU")
                    value: SystemStatService.cpuUsage
                    displayLabel: Math.round(SystemStatService.cpuUsage) + "%"
                    accentColor: SystemStatService.cpuUsage > 90 ? MatugenColors.md3.error : SystemStatService.cpuUsage > 70 ? MatugenColors.md3.tertiary : MatugenColors.md3.primary
                }
                StatRow {
                    icon: "memory"
                    label: Localization.t("dashboard.controls.resources.ram", "RAM")
                    value: SystemStatService.memPercent
                    displayLabel: SystemStatService.memGb + " G"
                    accentColor: SystemStatService.memPercent > 90 ? MatugenColors.md3.error : SystemStatService.memPercent > 70 ? MatugenColors.md3.tertiary : MatugenColors.md3.primary
                }
                StatRow {
                    icon: "storage"
                    label: Localization.t("dashboard.controls.resources.disk", "Disk")
                    value: SystemStatService.diskPercent
                    displayLabel: Math.round(SystemStatService.diskPercent) + "%"
                    accentColor: SystemStatService.diskPercent > 90 ? MatugenColors.md3.error : SystemStatService.diskPercent > 70 ? MatugenColors.md3.tertiary : MatugenColors.md3.primary
                }
                StatRow {
                    icon: "thermostat"
                    label: Localization.t("dashboard.controls.resources.temp", "Temp")
                    value: SystemStatService.cpuTemp
                    displayLabel: Math.round(SystemStatService.cpuTemp) + "°"
                    accentColor: SystemStatService.cpuTemp > 90 ? MatugenColors.md3.error : SystemStatService.cpuTemp > 70 ? MatugenColors.md3.tertiary : MatugenColors.md3.primary
                }
            }

            // ── Battery + Power Profiles ──────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 8
                visible: Battery.available
            }

            StatRow {
                visible: Battery.available
                icon: Battery.isCharging ? "battery_charging_full" : "battery_std"
                label: Localization.t("dashboard.controls.resources.battery", "Bat")
                value: Math.round(Battery.percentage * 100)
                displayLabel: Math.round(Battery.percentage * 100) + "%"
                accentColor: Battery.isCharging ? MatugenColors.md3.secondary : Battery.isLow ? MatugenColors.md3.error : MatugenColors.md3.primary
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 10
                implicitHeight: 34
                radius: 8
                color: ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.7)
                visible: !!PowerProfiles
                enabled: !root.win.btExpanded && !root.win.vpnExpanded

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: [
                            {
                                icon: "energy_savings_leaf",
                                label: Localization.t("dashboard.controls.powerProfiles.eco", "Eco"),
                                profile: PowerProfile.PowerSaver,
                                hint: "E"
                            },
                            {
                                icon: "balance",
                                label: Localization.t("dashboard.controls.powerProfiles.balanced", "Balanced"),
                                profile: PowerProfile.Balanced,
                                hint: "N"
                            },
                            {
                                icon: "speed",
                                label: Localization.t("dashboard.controls.powerProfiles.performance", "Performance"),
                                profile: PowerProfile.Performance,
                                hint: "P"
                            }
                        ]
                        delegate: Item {
                            required property var modelData
                            readonly property bool active: PowerProfiles?.profile === modelData.profile
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: parent.active
                                    ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.45)
                                    : ppMouse.containsMouse
                                        ? MatugenColors.md3.surface_container_highest
                                        : MatugenColors.md3.surface_container
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: parent.parent.parent.modelData.icon
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 15
                                        font.variableAxes: ({
                                                "FILL": 1
                                            })
                                        renderType: Text.NativeRendering
                                        color: parent.parent.parent.active ? MatugenColors.md3.on_primary : MatugenColors.md3.on_surface
                                        opacity: parent.parent.parent.active ? 1.0 : 0.45
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 120
                                            }
                                        }
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 120
                                            }
                                        }
                                    }
                                    Text {
                                        text: parent.parent.parent.modelData.label
                                        font.pixelSize: 13
                                        color: parent.parent.parent.active ? MatugenColors.md3.on_background : MatugenColors.md3.on_surface
                                        opacity: parent.parent.parent.active ? 1.0 : 0.35
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 120
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: ppMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (PowerProfiles)
                                    PowerProfiles.profile = parent.modelData.profile
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.bottomMargin: -2
                                anchors.rightMargin: 2
                                width: 14
                                height: 14
                                radius: 3
                                color: MatugenColors.md3.primary
                                opacity: root.win.tabHintMode ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                                z: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.parent.modelData.hint
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: MatugenColors.md3.on_primary
                                }
                            }
                        }
                    }
                }
            }

            Item {
                implicitHeight: 4
            }
        }
    }
}
