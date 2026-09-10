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
                onClicked: EjectPickerService.dismiss()
            }
        }
    }

    PanelWindow {
        id: win

        property bool isOpen: false
        property int  currentIndex: 0
        property var  devices: []        // [{dev, model, mountpoint}]
        property string pendingDev: ""   // dev currently being unmounted
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

        Connections {
            target: EjectPickerService
            function onVisibleChanged() {
                if (EjectPickerService.visible) {
                    win.devices = []
                    win.pendingDev = ""
                    win.currentIndex = 0
                    win.mouseActive = false
                    win.isOpen = true
                    deviceLoader.running = true
                } else {
                    closeTimer.restart()
                    win.isOpen = false
                }
            }
        }

        onIsOpenChanged: {
            if (isOpen) keyCapture.forceActiveFocus()
        }

        function navigate(delta) {
            mouseActive = false
            const n = devices.length
            if (n === 0) return
            currentIndex = (currentIndex + delta + n) % n
        }

        function ejectSelected() {
            const d = devices[currentIndex]
            if (!d || pendingDev) return
            pendingDev = d.dev
            unmountProcess.command = ["udisksctl", "unmount", "-b", d.dev]
            unmountProcess.running = true
        }

        function parseMountedDevice(line) {
            const name = /(?:^| )NAME="([^"]+)"/.exec(line)
            const removable = /(?:^| )RM="1"/.test(line)
            const mountpoint = /(?:^| )MOUNTPOINT="([^"]*)"/.exec(line)
            const model = /(?:^| )MODEL="([^"]*)"/.exec(line)
            if (!name || !removable || !mountpoint || !/^(\/media|\/run\/media)/.test(mountpoint[1]))
                return null
            return { dev: "/dev/" + name[1], model: model ? model[1] : "", mountpoint: mountpoint[1] }
        }

        Process {
            id: deviceLoader
            running: false
            command: ["lsblk", "-P", "-o", "NAME,RM,MOUNTPOINT,MODEL"]
            stdout: SplitParser {
                onRead: data => {
                    const device = win.parseMountedDevice(data)
                    if (device)
                        win.devices = [...win.devices, device]
                }
            }
            onExited: (exitCode) => {
                if (win.devices.length === 0) {
                    Quickshell.execDetached(["notify-send", Localization.t("notifications.eject.noDevices.title", "No devices"), Localization.t("notifications.eject.noDevices.body", "No removable devices mounted"), "-a", "Shell"])
                    EjectPickerService.dismiss()
                }
            }
        }

        Process {
            id: unmountProcess
            running: false
            onExited: (exitCode) => {
                if (exitCode !== 0) {
                    Quickshell.execDetached(["notify-send", Localization.t("notifications.eject.unmountFailed.title", "Unmount failed"),
                        Localization.t("notifications.eject.unmountFailed.body", "Could not unmount {device}", { device: win.pendingDev }), "-u", "normal", "-a", "Shell"])
                }
                win.devices = win.devices.filter(d => d.dev !== win.pendingDev)
                win.currentIndex = Math.min(win.currentIndex, Math.max(win.devices.length - 1, 0))
                win.pendingDev = ""
                if (win.devices.length === 0) EjectPickerService.dismiss()
            }
        }

        Timer { id: closeTimer; interval: 220; repeat: false }

        Keys.onEscapePressed: EjectPickerService.dismiss()

        MouseArea { anchors.fill: parent; enabled: win.isOpen; onClicked: EjectPickerService.dismiss() }

        Item {
            id: keyCapture
            focus: true
            Keys.onEscapePressed:  EjectPickerService.dismiss()
            Keys.onUpPressed:      win.navigate(-1)
            Keys.onDownPressed:    win.navigate(1)
            Keys.onReturnPressed:  win.ejectSelected()
            Keys.onPressed: function(event) {
                if (event.modifiers & Qt.ControlModifier) {
                    const sc = Globals.scanCodes
                    if (event.nativeScanCode === sc['N']) {
                        win.navigate(1); event.accepted = true
                    } else if (event.nativeScanCode === sc['P']) {
                        win.navigate(-1); event.accepted = true
                    }
                }
            }
        }

        // ── Center panel ─────────────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.35)
            width: 500
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

                    // ── Header ────────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 10

                        Text {
                            font.family: "Material Symbols Rounded"; font.pixelSize: 20
                            font.variableAxes: ({ "FILL": 1 })
                            renderType: Text.NativeRendering
                            color: MatugenColors.md3.on_surface; opacity: 0.5
                            text: "usb"  // usb
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Localization.t("ejectPicker.title", "Unmount device")
                            font.pixelSize: 15
                            color: MatugenColors.md3.on_surface; opacity: 0.5
                        }
                    }

                    // ── Device list ───────────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        clip: true
                        implicitHeight: Math.min(Math.max(win.devices.length, 1), 8) * 56
                        Behavior on implicitHeight {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }

                        ListView {
                            id: deviceList
                            anchors.fill: parent
                            clip: true
                            model: win.devices
                            currentIndex: win.currentIndex
                            highlightMoveDuration: 0

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: deviceList.width; height: 56

                                readonly property bool selected: index === win.currentIndex
                                readonly property bool pending:  win.pendingDev === modelData.dev

                                Rectangle {
                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                                    color: selected
                                        ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
                                    radius: Globals.componentRadius - 4
                                    Behavior on color { ColorAnimation { duration: 40 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                        spacing: 12

                                        Text {
                                            id: rowSpinner
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 22
                                            font.variableAxes: ({ "FILL": 1 })
                                            renderType: Text.NativeRendering
                                            color: MatugenColors.md3.primary
                                            text: pending ? "progress_activity" : "eject"  // spinner or storage
                                            opacity: pending ? 1.0 : 0.6
                                            NumberAnimation on rotation {
                                                from: 0; to: 360; duration: 900
                                                loops: Animation.Infinite; running: pending
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.model.length > 0 ? modelData.model : modelData.dev
                                                font.pixelSize: 15
                                                color: MatugenColors.md3.on_surface
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: pending ? Localization.t("ejectPicker.unmounting", "Unmounting...") : modelData.dev + "  " + modelData.mountpoint
                                                font.pixelSize: 12
                                                color: pending ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                                                opacity: pending ? 0.8 : 0.4
                                                elide: Text.ElideRight
                                                Behavior on color   { ColorAnimation  { duration: 150 } }
                                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { if (win.mouseActive) win.currentIndex = index }
                                        onClicked: {
                                            win.currentIndex = index
                                            win.ejectSelected()
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
}
