import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property int listHeight: targetListHeight
    readonly property int targetListHeight: 10 * 46
    readonly property bool isCalcMode: calculator.isCalcMode
    readonly property var activeList: cmdList
    property string pendingCustomCmd: ""
    readonly property string customScriptsDir: Settings.customScriptsPath === "~"
        ? Quickshell.env("HOME")
        : Settings.customScriptsPath.startsWith("~/")
            ? Quickshell.env("HOME") + Settings.customScriptsPath.slice(1)
            : Settings.customScriptsPath

    spacing: 8

    function activate() {
        cmdInput.text = "";
        cmdList.currentIndex = 0;
        cmdInput.forceActiveFocus();
        pathModel.clear();
        pathLoader.running = true;
    }

    property var filteredCmds: {
        const q = cmdInput.text.trim().toLowerCase();
        const all = [];
        const seen = new Set();
        for (let i = 0; i < pathModel.count; i++) {
            const n = pathModel.get(i).name;
            seen.add(n);
            all.push(n);
        }
        for (const cmd of RunStats.customCmds)
            if (!seen.has(cmd))
                all.push(cmd);
        if (q.length === 0)
            return RunStats.sortCmds(all);
        return RunStats.sortCmds(all.filter(n => n.toLowerCase().includes(q)));
    }

    Process {
        id: customCmdProcess
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0)
                RunStats.saveCustomCmd(root.pendingCustomCmd);
            root.pendingCustomCmd = "";
        }
    }

    Process {
        id: pathLoader
        running: false
        command: ["ls", "-1", root.customScriptsDir]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.length > 0)
                    pathModel.append({ name: line });
            }
        }
    }

    ListModel {
        id: pathModel
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44
        color: MatugenColors.md3.surface_container
        radius: Globals.componentRadius

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 10

            Text {
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                font.variableAxes: ({
                    "FILL": 1
                })
                renderType: Text.NativeRendering
                color: calculator.isCalcMode ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                opacity: 0.6
                text: calculator.isCalcMode ? "functions" : "terminal_2"
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            TextInput {
                id: cmdInput
                Layout.fillWidth: true
                font.pixelSize: 16
                color: MatugenColors.md3.on_surface
                selectionColor: MatugenColors.md3.primary
                clip: true
                onTextChanged: cmdList.currentIndex = 0

                Text {
                    anchors.fill: parent
                    text: Localization.t("launcher.placeholders.run", "Run...")
                    font: cmdInput.font
                    color: MatugenColors.md3.on_surface
                    opacity: 0.3
                    visible: cmdInput.text.length === 0
                    verticalAlignment: Text.AlignVCenter
                }

                Keys.onEscapePressed: RunLauncherService.dismiss()
                Keys.onUpPressed: {
                    cmdList.currentIndex = cmdList.currentIndex > 0 ? cmdList.currentIndex - 1 : Math.max(cmdList.count - 1, 0);
                }
                Keys.onDownPressed: {
                    cmdList.currentIndex = cmdList.currentIndex < cmdList.count - 1 ? cmdList.currentIndex + 1 : 0;
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Tab) {
                        const sel = root.filteredCmds[cmdList.currentIndex];
                        if (sel !== undefined) {
                            cmdInput.text = sel;
                            cmdInput.cursorPosition = cmdInput.text.length;
                        }
                        event.accepted = true;
                    } else if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_N) {
                            cmdList.currentIndex = cmdList.currentIndex < cmdList.count - 1 ? cmdList.currentIndex + 1 : 0;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_P) {
                            cmdList.currentIndex = cmdList.currentIndex > 0 ? cmdList.currentIndex - 1 : Math.max(cmdList.count - 1, 0);
                            event.accepted = true;
                        }
                    }
                }
                Keys.onReturnPressed: {
                    if (calculator.isCalcMode) {
                        calculator.copyResult();
                        RunLauncherService.dismiss();
                        return;
                    }

                    const selected = root.filteredCmds[cmdList.currentIndex];
                    const cmd = selected !== undefined ? selected : cmdInput.text.trim();
                    if (cmd.length > 0) {
                        RunStats.recordLaunch(cmd);
                        if (selected === undefined) {
                            root.pendingCustomCmd = cmd;
                            customCmdProcess.command = ["sh", "-c", cmd];
                            customCmdProcess.running = true;
                        } else {
                            Quickshell.execDetached(["sh", "-c", cmd]);
                        }
                        RunLauncherService.dismiss();
                    }
                }
            }
        }
    }

    Item {
        id: listArea
        Layout.fillWidth: true
        implicitHeight: root.listHeight
        clip: true

        CalculatorMode {
            id: calculator
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 72
            inputText: cmdInput.text
        }

        ListView {
            id: cmdList
            anchors.fill: parent
            visible: !calculator.isCalcMode
            clip: true
            model: root.filteredCmds
            currentIndex: 0
            highlightMoveDuration: 0

            delegate: Item {
                required property var modelData
                required property int index
                width: cmdList.width
                height: 46

                Rectangle {
                    anchors {
                        fill: parent
                        leftMargin: 2
                        rightMargin: 2
                        topMargin: 1
                        bottomMargin: 1
                    }
                    color: cmdRowArea.containsMouse || index === cmdList.currentIndex ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
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

                        Text {
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                            font.variableAxes: ({
                                "FILL": 1
                            })
                            renderType: Text.NativeRendering
                            color: MatugenColors.md3.primary
                            text: "terminal_2"
                            opacity: 0.7
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData
                            font.pixelSize: 15
                            color: MatugenColors.md3.on_surface
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: cmdRowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: cmdList.currentIndex = index
                        onClicked: {
                            RunStats.recordLaunch(modelData);
                            Quickshell.execDetached(["sh", "-c", modelData]);
                            RunLauncherService.dismiss();
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: !calculator.isCalcMode && cmdList.contentHeight > cmdList.height
            anchors {
                right: parent.right
                rightMargin: 4
                top: parent.top
                bottom: parent.bottom
            }
            width: 3
            radius: 1.5
            color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.8)

            Rectangle {
                width: parent.width
                height: cmdList.height > 0 ? Math.max(24, (cmdList.height / cmdList.contentHeight) * cmdList.height) : 0
                y: cmdList.height > 0 ? (cmdList.contentY / cmdList.contentHeight) * cmdList.height : 0
                radius: parent.radius
                color: MatugenColors.md3.on_surface
                opacity: 0.6
            }
        }
    }
}
