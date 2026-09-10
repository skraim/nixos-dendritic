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
                onClicked: VMPickerService.dismiss()
            }
        }
    }

    PanelWindow {
        id: win

        property bool isOpen: false
        property int  currentIndex: 0
        property string selectedName: ""    // survives reloads
        property var  vms: []
        property var  _stagingVms: []       // filled during parse, swapped atomically
        property bool isLoading: false
        property string pendingVmName: ""   // VM currently being acted on
        property string pendingAction: ""   // "starting" | "stopping"
        property bool mouseActive: false

        function displayState(state) {
            if (!state) return ""
            const text = String(state)
            const key = text.toLowerCase().split(" ").join("_")
            const fallback = text.charAt(0).toUpperCase() + text.slice(1)
            return Localization.t("vmPicker.status." + key, fallback)
        }

        function displayPendingState(action) {
            if (!action) return ""
            const key = String(action).toLowerCase().split(" ").join("_")
            return Localization.t("vmPicker.status." + key + "Progress", displayState(action) + "...")
        }

        property var filteredVMs: {
            const q = searchInput.text.trim().toLowerCase()
            const filtered = q.length === 0 ? vms : vms.filter(vm => vm.name.toLowerCase().includes(q))
            return filtered.slice().sort((a, b) => {
                const ar = a.state === "running", br = b.state === "running"
                if (ar !== br) return ar ? -1 : 1
                const ua = UsageTracker.get("vm:" + a.name)
                const ub = UsageTracker.get("vm:" + b.name)
                if (ua !== ub) return ub - ua
                return a.name.localeCompare(b.name)
            })
        }

        // Restore currentIndex by name after every vms refresh; clear pending if done
        onVmsChanged: Qt.callLater(function() {
            const idx = filteredVMs.findIndex(vm => vm.name === selectedName)
            currentIndex = idx >= 0 ? idx : 0

            if (pendingVmName) {
                const vm = vms.find(v => v.name === pendingVmName)
                if (vm) {
                    const done = (pendingAction === "starting" && vm.state === "running")
                              || (pendingAction === "stopping" && vm.state !== "running")
                    if (done) { pendingVmName = ""; pendingAction = "" }
                }
            }
        })

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
            target: VMPickerService
            function onVisibleChanged() {
                if (VMPickerService.visible) {
                    win.isOpen = true
                } else {
                    closeTimer.restart()
                    win.isOpen = false
                }
            }
        }

        onIsOpenChanged: {
            if (isOpen) {
                currentIndex  = 0
                selectedName  = ""
                mouseActive   = false
                pendingVmName = ""
                pendingAction = ""
                vms           = []
                _stagingVms   = []
                searchInput.text = ""
                isLoading = true
                listProcess.running = true
                searchInput.forceActiveFocus()
            } else {
                pollTimer.stop()
            }
        }

        function navigate(delta) {
            mouseActive = false
            const arr = filteredVMs
            if (arr.length === 0) return
            currentIndex = (currentIndex + delta + arr.length) % arr.length
            selectedName = filteredVMs[currentIndex]?.name ?? ""
            Qt.callLater(function() { vmList.positionViewAtIndex(currentIndex, ListView.Contain) })
        }

        function selectedVM() {
            return filteredVMs[currentIndex] ?? null
        }

        // Dynamic default action: view if running, start+view otherwise
        function activate() {
            const vm = selectedVM()
            if (!vm) return
            UsageTracker.record("vm:" + vm.name)
            if (vm.state === "running") {
                Quickshell.execDetached(["bash", "-c",
                    "virt-viewer -c qemu:///system " + vm.name])
            } else {
                Quickshell.execDetached(["bash", "-c",
                    "virsh -c qemu:///system start " + vm.name +
                    " && virt-viewer -c qemu:///system --wait " + vm.name])
            }
            VMPickerService.dismiss()
        }

        function startVM() {
            const vm = selectedVM()
            if (!vm || vm.state === "running") return
            pendingVmName = vm.name; pendingAction = "starting"
            Quickshell.execDetached(["bash", "-c",
                "virsh -c qemu:///system start " + vm.name])
        }

        function shutdownVM() {
            const vm = selectedVM()
            if (!vm || vm.state !== "running") return
            pendingVmName = vm.name; pendingAction = "stopping"
            Quickshell.execDetached(["bash", "-c",
                "virsh -c qemu:///system shutdown " + vm.name])
        }

        function viewVM() {
            const vm = selectedVM()
            if (!vm) return
            Quickshell.execDetached(["bash", "-c",
                "virt-viewer -c qemu:///system " + vm.name])
            VMPickerService.dismiss()
        }

        // Reload without clearing the displayed list (no flicker)
        function softReload() {
            if (listProcess.running) return
            _stagingVms = []
            listProcess.running = true
        }

        // ── virsh list --all parser ──────────────────────────────────────────
        Process {
            id: listProcess
            running: false
            command: ["bash", "-c",
                "virsh -c qemu:///system list --all 2>/dev/null | tail -n +3"]
            stdout: SplitParser {
                onRead: function(line) {
                    const trimmed = line.trim()
                    if (!trimmed) return
                    const parts = trimmed.split(/\s{2,}/)
                    if (parts.length < 3) return
                    const name  = parts[1]
                    const state = parts.slice(2).join(" ")
                    const arr = win._stagingVms.slice()
                    arr.push({ name, state })
                    win._stagingVms = arr
                }
            }
            onRunningChanged: {
                if (!running) {
                    win.vms = win._stagingVms   // atomic swap — no flicker
                    win.isLoading = false
                    if (win.isOpen) pollTimer.start()
                }
            }
        }

        // Poll every 3 s while picker is open so state stays current
        Timer {
            id: pollTimer
            interval: 3000; repeat: false
            onTriggered: win.softReload()
        }

        Timer {
            id: closeTimer
            interval: 220; repeat: false
            onTriggered: { vms = []; selectedName = ""; currentIndex = 0 }
        }

        Keys.onEscapePressed: VMPickerService.dismiss()

        MouseArea { anchors.fill: parent; enabled: win.isOpen; onClicked: VMPickerService.dismiss() }

        // ── Center panel ─────────────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.35)
            width: 580
            height: mainRect.height

            opacity: win.isOpen ? 1.0 : 0.0
            scale:   win.isOpen ? 1.0 : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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

                    // ── Search bar ───────────────────────────────────────────
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
                                color: MatugenColors.md3.on_surface_variant; opacity: 0.6
                                text: "computer"
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.pixelSize: 16
                                color: MatugenColors.md3.on_surface
                                selectionColor: MatugenColors.md3.primary
                                clip: true
                                onTextChanged: {
                                    win.currentIndex = 0
                                    win.selectedName = win.filteredVMs[0]?.name ?? ""
                                    win.mouseActive = false
                                }

                                Text {
                                    anchors.fill: parent
                                    text: Localization.t("vmPicker.search", "Search VMs...")
                                    font: searchInput.font
                                    color: MatugenColors.md3.on_surface; opacity: 0.3
                                    visible: searchInput.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Keys.onEscapePressed: VMPickerService.dismiss()
                                Keys.onUpPressed:     win.navigate(-1)
                                Keys.onDownPressed:   win.navigate(1)
                                Keys.onReturnPressed: win.activate()
                                Keys.onPressed: function(event) {
                                    const sc = Globals.scanCodes
                                    if (event.modifiers & Qt.ControlModifier) {
                                        if (event.nativeScanCode === sc['R']) {
                                            win.startVM(); event.accepted = true
                                        } else if (event.nativeScanCode === sc['S']) {
                                            win.shutdownVM(); event.accepted = true
                                        } else if (event.nativeScanCode === sc['V']) {
                                            win.viewVM(); event.accepted = true
                                        } else if (event.nativeScanCode === sc['N']) {
                                            win.navigate(1);  event.accepted = true
                                        } else if (event.nativeScanCode === sc['P']) {
                                            win.navigate(-1); event.accepted = true
                                        }
                                    }
                                }
                            }

                            // ── Action badges ────────────────────────────────
                            Repeater {
                                model: [
                                    { label: "^R", icon: "play_arrow", active: win.selectedVM() !== null && win.selectedVM()?.state !== "running" },
                                    { label: "^S", icon: "\ue8ac", active: win.selectedVM() !== null && win.selectedVM()?.state === "running" },
                                    { label: "^V", icon: "visibility", active: win.selectedVM() !== null }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    implicitHeight: 28
                                    implicitWidth: badgeRow.implicitWidth + 14
                                    radius: Globals.componentRadius - 4
                                    color: modelData.active
                                        ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4)
                                        : MatugenColors.md3.surface_container_low
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    RowLayout {
                                        id: badgeRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text {
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 13
                                            font.variableAxes: ({ "FILL": 1 })                                        
                                            renderType: Text.NativeRendering
                                            color: MatugenColors.md3.on_surface
                                            opacity: modelData.active ? 1.0 : 0.4
                                            text: modelData.icon
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                        Text {
                                            text: modelData.label
                                            font.pixelSize: 11
                                            color: MatugenColors.md3.on_surface
                                            opacity: modelData.active ? 0.85 : 0.35
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── VM list ──────────────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        clip: true
                        implicitHeight: Math.min(win.filteredVMs.length, 8) * 46
                        Behavior on implicitHeight {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }

                        ListView {
                            id: vmList
                            anchors.fill: parent
                            clip: true
                            model: win.filteredVMs
                            currentIndex: win.currentIndex
                            highlightMoveDuration: 0

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: vmList.width; height: 46

                                readonly property bool isSelected: index === win.currentIndex
                                readonly property bool isRunning: modelData.state === "running"
                                readonly property bool isPaused:  modelData.state === "paused"
                                readonly property bool isPending: win.pendingVmName === modelData.name

                                Rectangle {
                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                                    color: isSelected
                                        ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
                                    radius: Globals.componentRadius - 4
                                    Behavior on color { ColorAnimation { duration: 40 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                        spacing: 12

                                        // Spinner shown when action is pending, state icon otherwise
                                        Text {
                                            id: spinnerIcon
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                            font.variableAxes: ({ "FILL": 1 })                                        
                                            renderType: Text.NativeRendering
                                            color: MatugenColors.md3.primary
                                            text: "progress_activity"
                                            visible: isPending
                                            NumberAnimation on rotation {
                                                from: 0; to: 360; duration: 900
                                                loops: Animation.Infinite
                                                running: spinnerIcon.visible
                                            }
                                        }
                                        Text {
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                            font.variableAxes: ({ "FILL": 1 })                                        
                                            renderType: Text.NativeRendering
                                            color: isRunning ? MatugenColors.md3.secondary
                                                 : isPaused  ? MatugenColors.md3.tertiary
                                                 : MatugenColors.md3.on_surface
                                            opacity: isRunning ? 0.9 : isPaused ? 0.75 : 0.35
                                            text:  isRunning ? "play_arrow"
                                                 : isPaused  ? "pause"
                                                 : "\ue8ac"
                                            visible: !isPending
                                            Behavior on color   { ColorAnimation  { duration: 150 } }
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
                                            text: isPending ? win.displayPendingState(win.pendingAction) : win.displayState(modelData.state)
                                            font.pixelSize: 12
                                            color: isPending ? MatugenColors.md3.primary
                                                 : isRunning ? MatugenColors.md3.secondary
                                                 : isPaused  ? MatugenColors.md3.tertiary
                                                 : MatugenColors.md3.on_surface
                                            opacity: isPending ? 0.9 : isRunning ? 0.85 : 0.45
                                            Behavior on color   { ColorAnimation  { duration: 150 } }
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                    }

                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: {
                                            if (win.mouseActive) {
                                                win.currentIndex = index
                                                win.selectedName = modelData.name
                                            }
                                        }
                                        onClicked: {
                                            win.currentIndex = index
                                            win.selectedName = modelData.name
                                            win.activate()
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: vmList.contentHeight > vmList.height
                            anchors { right: parent.right; rightMargin: 4; top: parent.top; bottom: parent.bottom }
                            width: 3; radius: 1.5
                            color: MatugenColors.md3.outline_variant
                            Rectangle {
                                width: parent.width
                                height: vmList.height > 0
                                    ? Math.max(24, (vmList.height / vmList.contentHeight) * vmList.height) : 0
                                y: vmList.height > 0
                                    ? (vmList.contentY / vmList.contentHeight) * vmList.height : 0
                                radius: parent.radius
                                color: MatugenColors.md3.on_surface_variant; opacity: 0.6
                            }
                        }
                    }

                    // ── Loading / empty state ────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        readonly property bool shouldShow: win.isLoading
                            || (!win.isLoading && win.filteredVMs.length === 0)
                        visible: shouldShow
                        implicitHeight: shouldShow ? 44 : 0
                        clip: true
                        Behavior on implicitHeight { NumberAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: win.isLoading ? Localization.t("vmPicker.loading", "Loading...") : Localization.t("vmPicker.empty", "No virtual machines found")
                            font.pixelSize: 13
                            color: MatugenColors.md3.on_surface; opacity: 0.35
                        }
                    }
                }
            }
        }
    }
}
