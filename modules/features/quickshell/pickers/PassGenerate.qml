import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.services
import qs.utils

Scope {
    property var passEntries: []

    Process {
        running: true
        command: ["bash", "-c", "PREFIX=\"${PASSWORD_STORE_DIR:-$HOME/.password-store}\"; " + "find \"$PREFIX\" -type f -name '*.gpg' 2>/dev/null " + "| sed \"s|$PREFIX/||; s|\\.gpg$||\" | sort"]
        stdout: SplitParser {
            onRead: data => {
                if (data.length > 0)
                    passEntries = [...passEntries, data];
            }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusiveZone: -1
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            visible: genWindow.visible
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: genWindow.isOpen ? 0.5 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: PassGenerateService.dismiss()
            }
        }
    }

    PanelWindow {
        id: genWindow

        property bool isOpen: false
        property string displayMode: ""    // "pass" | "otp", snapshotted on open
        property string scope: "personal"  // "personal" | "work"

        // Maps service mode to the actual store path prefix word
        property string modePrefix: displayMode === "otp" ? "otp" : "general"

        function updateScope(newScope) {
            if (scope === newScope)
                return;
            const oldPrefix = modePrefix + "/" + scope + "/";
            const suffix = keyInput.text.startsWith(oldPrefix) ? keyInput.text.substring(oldPrefix.length) : "";
            scope = newScope;
            keyInput.text = modePrefix + "/" + scope + "/" + suffix;
            keyInput.cursorPosition = keyInput.text.length;
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
            target: PassGenerateService
            function onVisibleChanged() {
                if (PassGenerateService.visible) {
                    genWindow.displayMode = PassGenerateService.mode;
                    genWindow.scope = "personal";
                    genWindow.isOpen = true;
                } else {
                    closeTimer.restart();
                    genWindow.isOpen = false;
                }
            }
        }

        onIsOpenChanged: {
            if (isOpen) {
                keyInput.text = modePrefix + "/" + scope + "/";
                keyInput.cursorPosition = keyInput.text.length;
                keyInput.forceActiveFocus();
            }
        }

        Timer {
            id: closeTimer
            interval: 220
            repeat: false
        }

        Keys.onEscapePressed: PassGenerateService.dismiss()

        MouseArea {
            anchors.fill: parent
            enabled: genWindow.isOpen
            onClicked: PassGenerateService.dismiss()
        }

        // ── Center panel ──────────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.35)
            width: 500
            height: mainRect.height

            opacity: genWindow.isOpen ? 1.0 : 0.0
            scale: genWindow.isOpen ? 1.0 : 0.96
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
                height: content.implicitHeight + 24
                color: MatugenColors.md3.surface
                radius: Globals.componentRadius
                clip: true

                ColumnLayout {
                    id: content
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 12
                    }
                    spacing: 8

                    // ── Header ────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 12

                        Text {
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 24
                            font.variableAxes: ({
                                    "FILL": 1
                                })
                            renderType: Text.NativeRendering
                            color: MatugenColors.md3.primary
                            text: genWindow.displayMode === "otp" ? "123" : "lock"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: genWindow.displayMode === "otp" ? Localization.t("passGenerate.title.otp", "New OTP Entry") : Localization.t("passGenerate.title.password", "New Password Entry")
                                font.pixelSize: 16
                                color: MatugenColors.md3.on_surface
                            }
                            Text {
                                text: Localization.t("passGenerate.examplePrefix", "e.g.") + "  " + genWindow.modePrefix + "/" + genWindow.scope + "/example.com"
                                font.pixelSize: 12
                                color: MatugenColors.md3.on_surface
                                opacity: 0.4
                            }
                        }
                    }

                    // ── Key input + scope toggle ──────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        color: MatugenColors.md3.surface_container
                        radius: Globals.componentRadius

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 14
                                rightMargin: 8
                            }
                            spacing: 10

                            Text {
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                color: MatugenColors.md3.on_surface
                                opacity: 0.5
                                text: "list_alt_add"
                            }

                            TextInput {
                                id: keyInput
                                Layout.fillWidth: true
                                font.pixelSize: 15
                                color: MatugenColors.md3.on_surface
                                selectionColor: MatugenColors.md3.primary
                                clip: true

                                Keys.onEscapePressed: PassGenerateService.dismiss()
                                Keys.onReturnPressed: {
                                    const key = keyInput.text.trim();
                                    if (key.length > 0) {
                                        PassGenerateService.execute(key);
                                        PassGenerateService.dismiss();
                                    }
                                }
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Tab) {
                                        genWindow.updateScope(genWindow.scope === "personal" ? "work" : "personal");
                                        event.accepted = true;
                                    }
                                }
                            }

                            // Personal / Work scope toggle
                            Rectangle {
                                implicitHeight: 30
                                implicitWidth: scopeRow.implicitWidth + 6
                                radius: Globals.componentRadius - 4
                                color: MatugenColors.md3.surface_container_low

                                RowLayout {
                                    id: scopeRow
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Repeater {
                                        model: ["personal", "work"]
                                        delegate: Rectangle {
                                            required property string modelData
                                            implicitWidth: scopeLbl.implicitWidth + 20
                                            implicitHeight: 24
                                            radius: Globals.componentRadius - 6
                                            color: genWindow.scope === modelData ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4) : "transparent"
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }

                                            Text {
                                                id: scopeLbl
                                                anchors.centerIn: parent
                                                text: parent.modelData
                                                font.pixelSize: 13
                                                color: MatugenColors.md3.on_surface
                                                opacity: genWindow.scope === parent.modelData ? 1.0 : 0.45
                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    genWindow.updateScope(parent.modelData);
                                                    keyInput.forceActiveFocus();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Existing entries (conflict check) ─────────────────
                    Item {
                        id: matchList
                        Layout.fillWidth: true
                        clip: true

                        property var entries: {
                            const q = keyInput.text.toLowerCase();
                            if (q.length < 3)
                                return [];
                            return passEntries.filter(e => e.toLowerCase().includes(q)).slice(0, 5);
                        }

                        implicitHeight: entries.length > 0 ? matchContent.implicitHeight : 0
                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }

                        ColumnLayout {
                            id: matchContent
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            spacing: 0

                            Repeater {
                                model: matchList.entries
                                delegate: ColumnLayout {
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 0

                                    // Divider (not before first item)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 1
                                        visible: index > 0
                                        color: MatugenColors.md3.outline_variant
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        Layout.leftMargin: 4
                                        Layout.rightMargin: 4
                                        spacing: 10

                                        Text {
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 15
                                            font.variableAxes: ({
                                                    "FILL": 1
                                                })
                                            renderType: Text.NativeRendering
                                            color: MatugenColors.md3.primary
                                            opacity: 0.45
                                            text: genWindow.displayMode === "otp" ? "123" : "lock"
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData
                                            font.pixelSize: 13
                                            color: MatugenColors.md3.on_surface
                                            opacity: 0.5
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
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
