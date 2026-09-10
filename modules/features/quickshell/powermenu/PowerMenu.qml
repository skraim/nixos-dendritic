import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.services
import qs.utils

Scope {
    Variants {
        model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData

        property bool isOpen: false
        property int selectedIndex: 0
        property string uptimeText: ""
        property string pendingCmd: ""
        property string pendingLabel: ""
        property int confirmSelectedIndex: 0
        property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(modelData)
        readonly property bool confirmMode: pendingCmd !== ""

        readonly property var actions: [
            {
                key: "X",
                icon: "\ue897",
                label: Localization.t("powerMenu.actions.lock", "Lock"),
                cmd: Settings.powerMenuCmds.lock,
                confirm: false
            },
            {
                key: "D",
                icon: "\ue333",
                label: Localization.t("powerMenu.actions.monitorOff", "Monitor off"),
                cmd: Settings.powerMenuCmds.monitorOff,
                confirm: false
            },
            {
                key: "U",
                icon: "\uef44",
                label: Localization.t("powerMenu.actions.suspend", "Suspend"),
                cmd: Settings.powerMenuCmds.suspend,
                confirm: true
            },
            {
                key: "Q",
                icon: "logout",
                label: Localization.t("powerMenu.actions.logout", "Logout"),
                cmd: Settings.powerMenuCmds.logout,
                confirm: true
            },
            {
                key: "R",
                icon: "autorenew",
                label: Localization.t("powerMenu.actions.reboot", "Reboot"),
                cmd: Settings.powerMenuCmds.reboot,
                confirm: true
            },
            {
                key: "S",
                icon: "\ue8ac",
                label: Localization.t("powerMenu.actions.shutdown", "Shutdown"),
                cmd: Settings.powerMenuCmds.shutdown,
                confirm: true
            }
        ]
        readonly property int menuColumns: columnsForScreen()

        visible: isOpen || closeTimer.running
        color: "transparent"
        screen: modelData
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        Connections {
            target: PowerMenuService
            function onVisibleChanged() {
                if (PowerMenuService.visible) {
                    if (!win.hyprMonitor?.focused) {
                        win.isOpen = false;
                        return;
                    }
                    win.selectedIndex = 0;
                    win.confirmSelectedIndex = 0;
                    win.uptimeText = "";
                    win.isOpen = true;
                    uptimeProcess.running = true;
                    keyCapture.forceActiveFocus();
                } else {
                    const wasOpen = win.isOpen;
                    win.pendingCmd = "";
                    win.pendingLabel = "";
                    win.confirmSelectedIndex = 0;
                    if (wasOpen)
                        closeTimer.restart();
                    win.isOpen = false;
                }
            }
        }

        function runCommand(cmd) {
            Quickshell.execDetached(["setsid", "sh", "-c", cmd]);
            PowerMenuService.dismiss();
        }

        function activate(action) {
            if (action.confirm) {
                win.pendingCmd = action.cmd;
                win.pendingLabel = action.label;
                win.confirmSelectedIndex = 0;
            } else {
                win.runCommand(action.cmd);
            }
        }

        function columnsForScreen() {
            const names = [
                win.hyprMonitor?.description,
                win.hyprMonitor?.name,
                win.modelData?.name
            ].filter(name => name !== undefined && name !== null && String(name).length > 0);
            for (const name of names) {
                const configured = Number(Settings.powerMenuMonitorColumns[String(name)]);
                if (configured >= 1 && configured <= win.actions.length)
                    return Math.floor(configured);
            }
            return win.actions.length;
        }

        Process {
            id: uptimeProcess
            running: false
            command: ["uptime"]
            stdout: SplitParser {
                onRead: function (line) {
                    const match = / up\\s+(.+?),/.exec(line);
                    win.uptimeText = match ? match[1] : "";
                }
            }
        }

        Timer {
            id: closeTimer
            interval: 200
            repeat: false
        }

        // ── Keyboard ─────────────────────────────────────────────────────────
        Item {
            id: keyCapture
            focus: true

            Keys.onEscapePressed: {
                if (win.confirmMode) {
                    win.pendingCmd = "";
                    win.pendingLabel = "";
                    win.confirmSelectedIndex = 0;
                } else {
                    PowerMenuService.dismiss();
                }
            }

            Keys.onLeftPressed: {
                if (win.confirmMode)
                    win.confirmSelectedIndex = 0;
                else
                    win.selectedIndex = (win.selectedIndex - 1 + win.actions.length) % win.actions.length;
            }

            Keys.onRightPressed: {
                if (win.confirmMode)
                    win.confirmSelectedIndex = 1;
                else
                    win.selectedIndex = (win.selectedIndex + 1) % win.actions.length;
            }

            Keys.onUpPressed: {
                if (!win.confirmMode && win.menuColumns < win.actions.length)
                    win.selectedIndex = (win.selectedIndex - win.menuColumns + win.actions.length) % win.actions.length;
            }

            Keys.onDownPressed: {
                if (!win.confirmMode && win.menuColumns < win.actions.length)
                    win.selectedIndex = (win.selectedIndex + win.menuColumns) % win.actions.length;
            }

            Keys.onReturnPressed: {
                if (win.confirmMode) {
                    if (win.confirmSelectedIndex === 0) {
                        win.runCommand(win.pendingCmd);
                    } else {
                        win.pendingCmd = "";
                        win.pendingLabel = "";
                        win.confirmSelectedIndex = 0;
                    }
                } else {
                    win.activate(win.actions[win.selectedIndex]);
                }
            }

            Keys.onPressed: function (event) {
                if (!win.isOpen)
                    return;
                const s = Globals.scanCodes;
                if (win.confirmMode) {
                    if (event.nativeScanCode === s['Y']) {
                        win.runCommand(win.pendingCmd);
                        event.accepted = true;
                    } else if (event.nativeScanCode === s['N']) {
                        win.pendingCmd = "";
                        win.pendingLabel = "";
                        win.confirmSelectedIndex = 0;
                        event.accepted = true;
                    }
                    return;
                }

                for (let i = 0; i < win.actions.length; i++) {
                    const expected = s[win.actions[i].key];
                    if (event.nativeScanCode === expected) {
                        win.selectedIndex = i;
                        win.activate(win.actions[i]);
                        event.accepted = true;
                        break;
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: win.isOpen
            onClicked: PowerMenuService.dismiss()
        }

        // ── Main view ────────────────────────────────────────────────────────
        Item {
            anchors.fill: parent

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

            // ── Columns ─────────────────────────────────────────────────────
            GridLayout {
                anchors.fill: parent
                anchors.margins: 14
                columns: win.menuColumns
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: win.actions

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === win.selectedIndex
                        readonly property int selectionAnimDuration: 140

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 1
                        radius: 0
                        color: isSelected ? MatugenColors.md3.primary_container : ColorUtils.transparentize(MatugenColors.md3.surface_container, 0.1)

                        Behavior on color {
                            ColorAnimation {
                                duration: selectionAnimDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.width: 1
                            border.color: isSelected ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.78) : ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.9)
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: selectionAnimDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 32
                            spacing: 18

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                font.family: "Material Symbols Rounded"
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                font.pixelSize: 84
                                color: isSelected ? MatugenColors.md3.on_primary_container : ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.18)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: selectionAnimDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.fillWidth: true
                                text: modelData.label
                                horizontalAlignment: Text.AlignHCenter
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                wrapMode: Text.Wrap
                                font.pixelSize: 30
                                minimumPixelSize: 18
                                fontSizeMode: Text.HorizontalFit
                                font.letterSpacing: 0.5
                                color: isSelected ? MatugenColors.md3.on_primary_container : MatugenColors.md3.on_surface
                                opacity: isSelected ? 1.0 : 0.58
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: selectionAnimDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: badge.implicitWidth + 22
                                implicitHeight: 30
                                radius: 6
                                color: ColorUtils.transparentize(isSelected ? MatugenColors.md3.on_primary_container : MatugenColors.md3.on_surface, 0.88)

                                Text {
                                    id: badge
                                    anchors.centerIn: parent
                                    text: modelData.key
                                    font.pixelSize: 16
                                    color: isSelected ? MatugenColors.md3.on_primary_container : MatugenColors.md3.on_surface
                                    opacity: 0.86
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: win.isOpen && !win.confirmMode
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: win.selectedIndex = index
                            onClicked: {
                                win.selectedIndex = index;
                                win.activate(modelData);
                            }
                        }
                    }
                }
            }

            // ── Uptime ───────────────────────────────────────────────────────
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 28
                z: 1
                implicitWidth: uptimeLabel.implicitWidth + 32
                implicitHeight: 38
                radius: 8
                color: ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.18)
                border.width: 1
                border.color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.82)

                Text {
                    id: uptimeLabel
                    anchors.centerIn: parent
                    text: win.uptimeText.length > 0 ? Localization.t("powerMenu.uptimeLabel", "Uptime") + "  " + win.uptimeText : ""
                    font.pixelSize: 20
                    font.letterSpacing: 1
                    color: MatugenColors.md3.on_surface
                    opacity: 0.78
                }
            }
        }

        // ── Confirm box ──────────────────────────────────────────────────────
        Item {
            anchors.centerIn: parent
            width: confirmBox.width
            height: confirmBox.height

            opacity: win.confirmMode ? 1.0 : 0.0
            scale: win.confirmMode ? 1.0 : 0.94
            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
            visible: opacity > 0

            MouseArea {
                anchors.fill: parent
            }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 28
                samples: 48
                color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.68)
            }

            Rectangle {
                id: confirmBox
                readonly property int contentMargin: 27

                width: Math.max(380, confirmRow.implicitWidth + 96)
                height: confirmCol.implicitHeight + (contentMargin * 2)
                color: ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.06)
                radius: 10

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.84)
                }

                ColumnLayout {
                    id: confirmCol
                    anchors.fill: parent
                    anchors.margins: confirmBox.contentMargin
                    spacing: 18

                    // Label
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            text: win.pendingLabel
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: 32
                            font.letterSpacing: 0.5
                            color: MatugenColors.md3.on_surface
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Localization.t("powerMenu.confirm.areYouSure", "Are you sure?")
                            font.pixelSize: 18
                            color: MatugenColors.md3.on_surface
                            opacity: 0.4
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.88)
                    }

                    // Y / N
                    RowLayout {
                        id: confirmRow
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        // Yes
                        Rectangle {
                            id: yesButton
                            readonly property bool isSelected: win.confirmSelectedIndex === 0

                            implicitWidth: Math.max(128, yInner.implicitWidth + 36)
                            implicitHeight: 46
                            radius: 8
                            color: isSelected ? MatugenColors.md3.primary_container : MatugenColors.md3.surface_container
                            Behavior on color {
                                ColorAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: 1
                                border.color: parent.isSelected ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.78) : ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.86)
                            }

                            RowLayout {
                                id: yInner
                                anchors.centerIn: parent
                                spacing: 10

                                Rectangle {
                                    implicitWidth: yKey.implicitWidth + 10
                                    implicitHeight: 24
                                    radius: 4
                                    color: yesButton.isSelected ? ColorUtils.transparentize(MatugenColors.md3.on_primary_container, 0.88) : ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.9)
                                    Text {
                                        id: yKey
                                        anchors.centerIn: parent
                                        text: "Y"
                                        font.pixelSize: 13
                                        color: yesButton.isSelected ? MatugenColors.md3.on_primary_container : MatugenColors.md3.on_surface
                                        opacity: 0.8
                                    }
                                }
                                Text {
                                    text: Localization.t("powerMenu.confirm.yes", "Yes")
                                    font.pixelSize: 24
                                    color: yesButton.isSelected ? MatugenColors.md3.on_primary_container : MatugenColors.md3.on_surface
                                }
                            }

                            MouseArea {
                                id: yArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.confirmSelectedIndex = 0
                                onClicked: win.runCommand(win.pendingCmd)
                            }
                        }

                        // No
                        Rectangle {
                            id: noButton
                            readonly property bool isSelected: win.confirmSelectedIndex === 1

                            implicitWidth: Math.max(128, nInner.implicitWidth + 36)
                            implicitHeight: 46
                            radius: 8
                            color: isSelected ? MatugenColors.md3.surface_container_highest : MatugenColors.md3.surface_container
                            Behavior on color {
                                ColorAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: 1
                                border.color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.86)
                            }

                            RowLayout {
                                id: nInner
                                anchors.centerIn: parent
                                spacing: 10

                                Rectangle {
                                    implicitWidth: nKey.implicitWidth + 10
                                    implicitHeight: 24
                                    radius: 4
                                    color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.9)
                                    Text {
                                        id: nKey
                                        anchors.centerIn: parent
                                        text: "N"
                                        font.pixelSize: 13
                                        color: MatugenColors.md3.on_surface
                                        opacity: 0.8
                                    }
                                }
                                Text {
                                    text: Localization.t("powerMenu.confirm.no", "No")
                                    font.pixelSize: 24
                                    color: MatugenColors.md3.on_surface
                                }
                            }

                            MouseArea {
                                id: nArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.confirmSelectedIndex = 1
                                onClicked: {
                                    win.pendingCmd = "";
                                    win.pendingLabel = "";
                                    win.confirmSelectedIndex = 0;
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
