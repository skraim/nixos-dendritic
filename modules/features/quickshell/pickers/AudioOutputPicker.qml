import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
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
            visible: win.visible

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: win.isOpen ? 0.5 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: AudioOutputPickerService.dismiss()
            }
        }
    }

    PanelWindow {
        id: win

        property bool isOpen: false
        property string selectedNodeName: ""
        readonly property int currentIndex: filteredOutputs.findIndex(n => n.name === selectedNodeName)
        property bool mouseActive: false

        property var outputs: {
            const r = [];
            for (const n of Pipewire.nodes.values)
                if (n.audio && !n.isStream && n.isSink)
                    r.push(n);
            return r;
        }

        property var filteredOutputs: {
            const q = searchInput.text.trim().toLowerCase()
            const base = q.length === 0 ? outputs : outputs.filter(n => {
                const label = win.nodeLabel(n).toLowerCase()
                const name = (n.name || "").toLowerCase()
                const desc = (n.description || "").toLowerCase()
                const nick = (n.nickname || "").toLowerCase()
                return label.includes(q) || name.includes(q) || desc.includes(q) || nick.includes(q)
            })

            return base.slice().sort((a, b) => {
                const aa = win.isActive(a), ba = win.isActive(b)
                if (aa !== ba) return aa ? -1 : 1

                const av = win.isAvailable(a), bv = win.isAvailable(b)
                if (av !== bv) return av ? -1 : 1

                const ua = UsageTracker.get("audio-output:" + a.name)
                const ub = UsageTracker.get("audio-output:" + b.name)
                if (ua !== ub) return ub - ua

                return win.nodeLabel(a).localeCompare(win.nodeLabel(b))
            })
        }

        visible: isOpen || closeTimer.running
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        anchors.top: true; anchors.bottom: true
        anchors.left: true; anchors.right: true

        Connections {
            target: AudioOutputPickerService
            function onVisibleChanged() {
                if (AudioOutputPickerService.visible) {
                    win.isOpen = true
                } else {
                    closeTimer.restart()
                    win.isOpen = false
                }
            }
        }

        onIsOpenChanged: {
            if (isOpen) {
                mouseActive = false
                searchInput.text = ""
                selectedNodeName = initialSelectionName()
                searchInput.forceActiveFocus()
            }
        }

        function nodeLabel(node) {
            return node ? (node.nickname || node.description || node.name || Localization.t("audioOutputPicker.unknownOutput", "Unknown output")) : Localization.t("audioOutputPicker.unknownOutput", "Unknown output")
        }

        function isActive(node) {
            return node && Pipewire.defaultAudioSink && node.name === Pipewire.defaultAudioSink.name
        }

        function isAvailable(node) {
            if (!node || !node.audio) return false
            if (node.available === false || node.audio.available === false) return false

            const availability = (node.availability ?? node.audio.availability ?? "").toString().toLowerCase()
            if (availability === "no" || availability === "unavailable") return false

            const props = node.properties || node.audio.properties || ({})
            const portAvailability = (props["port.availability"] ?? props["device.profile.available"] ?? "").toString().toLowerCase()
            return portAvailability !== "no" && portAvailability !== "unavailable"
        }

        function initialSelectionName() {
            const active = filteredOutputs.find(n => isActive(n) && isAvailable(n))
            if (active) return active.name

            const available = filteredOutputs.find(n => isAvailable(n))
            if (available) return available.name

            return filteredOutputs.length > 0 ? filteredOutputs[0].name : ""
        }

        function nearestAvailableIndex(start, delta) {
            const n = filteredOutputs.length
            if (n === 0) return -1

            for (let i = 0; i < n; i++) {
                const idx = (start + (delta * i) + n) % n
                if (isAvailable(filteredOutputs[idx])) return idx
            }

            return -1
        }

        function navigate(delta) {
            mouseActive = false
            const n = filteredOutputs.length
            if (n === 0) return

            const cur = currentIndex < 0 ? (delta > 0 ? -1 : 0) : currentIndex
            const idx = nearestAvailableIndex(cur + delta, delta)
            if (idx >= 0) selectedNodeName = filteredOutputs[idx].name
        }

        function selectNode(node) {
            if (!node || !isAvailable(node)) return
            UsageTracker.record("audio-output:" + node.name)
            Pipewire.preferredDefaultAudioSink = node
            AudioOutputPickerService.dismiss()
        }

        Timer { id: closeTimer; interval: 220; repeat: false }

        Keys.onEscapePressed: AudioOutputPickerService.dismiss()

        MouseArea { anchors.fill: parent; enabled: win.isOpen; onClicked: AudioOutputPickerService.dismiss() }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.35)
            width: 500
            height: mainRect.height

            opacity: win.isOpen ? 1.0 : 0.0
            scale: win.isOpen ? 1.0 : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }
            HoverHandler { onPointChanged: win.mouseActive = true }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 2
                radius: 12; samples: 22; color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.5)
            }

            Rectangle {
                id: mainRect
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: panelCol.implicitHeight + 24
                color: MatugenColors.md3.surface
                radius: Globals.componentRadius
                clip: true

                ColumnLayout {
                    id: panelCol
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        color: MatugenColors.md3.surface_container
                        radius: Globals.componentRadius

                        RowLayout {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                            spacing: 10

                            Text {
                                font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                color: MatugenColors.md3.on_surface
                                opacity: 0.55
                                text: "volume_up"
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.pixelSize: 16
                                color: MatugenColors.md3.on_surface
                                selectionColor: MatugenColors.md3.primary
                                clip: true
                                onTextChanged: Qt.callLater(function() {
                                    const filtered = win.filteredOutputs
                                    if (!filtered.some(n => n.name === win.selectedNodeName && win.isAvailable(n)))
                                        win.selectedNodeName = win.initialSelectionName()
                                })

                                Text {
                                    anchors.fill: parent
                                    text: Localization.t("audioOutputPicker.search", "Search outputs...")
                                    font: searchInput.font
                                    color: MatugenColors.md3.on_surface; opacity: 0.3
                                    visible: searchInput.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Keys.onEscapePressed: AudioOutputPickerService.dismiss()
                                Keys.onUpPressed: win.navigate(-1)
                                Keys.onDownPressed: win.navigate(1)
                                Keys.onReturnPressed: win.selectNode(win.filteredOutputs[win.currentIndex])
                                Keys.onPressed: function(event) {
                                    if (event.modifiers & Qt.ControlModifier) {
                                        if (event.key === Qt.Key_N) {
                                            win.navigate(1); event.accepted = true
                                        } else if (event.key === Qt.Key_P) {
                                            win.navigate(-1); event.accepted = true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        clip: true
                        implicitHeight: Math.min(win.filteredOutputs.length, 8) * 46
                        Behavior on implicitHeight {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }

                        ListView {
                            id: outputList
                            anchors.fill: parent
                            clip: true
                            model: win.filteredOutputs
                            currentIndex: win.currentIndex
                            highlightMoveDuration: 0

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: outputList.width; height: 46

                                readonly property bool active: win.isActive(modelData)
                                readonly property bool available: win.isAvailable(modelData)
                                readonly property bool selected: index === win.currentIndex

                                Rectangle {
                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                                    color: selected && available
                                        ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65)
                                        : "transparent"
                                    radius: Globals.componentRadius - 4
                                    Behavior on color { ColorAnimation { duration: 40 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                        spacing: 12
                                        opacity: available ? 1.0 : 0.42

                                        Text {
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                            font.variableAxes: ({ "FILL": 1 })
                                            renderType: Text.NativeRendering
                                            color: active ? MatugenColors.md3.secondary : MatugenColors.md3.on_surface
                                            opacity: active ? 0.9 : 0.45
                                            text: active ? "check_circle" : Icons.getAudioSinkIcon((modelData.name || "").startsWith("bluez"), modelData)
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: win.nodeLabel(modelData)
                                            font.pixelSize: 15
                                            color: MatugenColors.md3.on_surface
                                            elide: Text.ElideRight
                                        }

                                    }

                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        hoverEnabled: available
                                        enabled: available
                                        cursorShape: available ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onEntered: { if (win.mouseActive) win.selectedNodeName = modelData.name }
                                        onClicked: {
                                            win.selectedNodeName = modelData.name
                                            win.selectNode(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        readonly property bool shouldShow: win.filteredOutputs.length === 0
                        visible: shouldShow
                        implicitHeight: shouldShow ? 44 : 0
                        clip: true
                        Behavior on implicitHeight { NumberAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: win.outputs.length === 0 ? Localization.t("audioOutputPicker.empty.noOutputs", "No outputs detected") : Localization.t("common.noMatches", "No matches")
                            font.pixelSize: 13
                            color: MatugenColors.md3.on_surface; opacity: 0.35
                        }
                    }
                }
            }
        }
    }
}
