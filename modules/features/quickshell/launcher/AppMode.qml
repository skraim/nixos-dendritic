import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property int listHeight: targetListHeight
    readonly property int targetListHeight: 10 * 46
    readonly property bool isCalcMode: calculator.isCalcMode
    readonly property var activeList: appList

    spacing: 8

    function activate() {
        searchInput.text = "";
        appList.currentIndex = 0;
        searchInput.forceActiveFocus();
    }

    function launchApp(app) {
        LauncherStats.recordLaunch(app.id);
        if (app.runInTerminal) {
            const exec = app.execString.replace(/%[uUfFdDnNickvm]/g, "").trim();
            Quickshell.execDetached([Settings.terminal, "--", "sh", "-c", exec]);
        } else {
            app.execute();
        }
    }

    property var filteredApps: {
        const q = searchInput.text.trim();
        const all = AppSearch.list.filter(e => !e.noDisplay);
        if (q.length === 0)
            return LauncherStats.sortApps(all);

        const fuzzy = AppSearch.fuzzyQuery(q).filter(e => !e.noDisplay);
        const seen = new Set(fuzzy.map(e => e.id));
        const ql = q.toLowerCase();
        const extras = all.filter(e => {
            if (seen.has(e.id))
                return false;
            if (e.id.toLowerCase().includes(ql))
                return true;
            if (e.genericName && e.genericName.toLowerCase().includes(ql))
                return true;
            const bin = e.execString.split(/\s+/)[0].split("/").pop().toLowerCase();
            return bin.includes(ql);
        });
        return [...fuzzy, ...extras];
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
                text: calculator.isCalcMode ? "functions" : "\ue8b6"
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                font.pixelSize: 16
                color: MatugenColors.md3.on_surface
                selectionColor: MatugenColors.md3.primary
                clip: true
                onTextChanged: appList.currentIndex = 0

                Text {
                    anchors.fill: parent
                    text: Localization.t("launcher.placeholders.search", "Search...")
                    font: searchInput.font
                    color: MatugenColors.md3.on_surface
                    opacity: 0.3
                    visible: searchInput.text.length === 0
                    verticalAlignment: Text.AlignVCenter
                }

                Keys.onEscapePressed: AppLauncherService.dismiss()
                Keys.onUpPressed: {
                    if (!calculator.isCalcMode)
                        appList.currentIndex = appList.currentIndex > 0 ? appList.currentIndex - 1 : Math.max(appList.count - 1, 0);
                }
                Keys.onDownPressed: {
                    if (!calculator.isCalcMode)
                        appList.currentIndex = appList.currentIndex < appList.count - 1 ? appList.currentIndex + 1 : 0;
                }
                Keys.onPressed: function(event) {
                    if (calculator.isCalcMode)
                        return;
                    if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_N) {
                            appList.currentIndex = appList.currentIndex < appList.count - 1 ? appList.currentIndex + 1 : 0;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_P) {
                            appList.currentIndex = appList.currentIndex > 0 ? appList.currentIndex - 1 : Math.max(appList.count - 1, 0);
                            event.accepted = true;
                        }
                    }
                }
                Keys.onReturnPressed: {
                    if (calculator.isCalcMode) {
                        calculator.copyResult();
                        AppLauncherService.dismiss();
                        return;
                    }

                    const app = root.filteredApps[appList.currentIndex];
                    if (app) {
                        root.launchApp(app);
                        AppLauncherService.dismiss();
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
            inputText: searchInput.text
        }

        ListView {
            id: appList
            anchors.fill: parent
            visible: !calculator.isCalcMode
            clip: true
            model: root.filteredApps
            currentIndex: 0
            highlightMoveDuration: 0

            delegate: Item {
                required property var modelData
                required property int index
                width: appList.width
                height: 46

                Rectangle {
                    anchors {
                        fill: parent
                        leftMargin: 2
                        rightMargin: 2
                        topMargin: 1
                        bottomMargin: 1
                    }
                    color: appRowArea.containsMouse || index === appList.currentIndex ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
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

                        Item {
                            width: 30
                            height: 30
                            Image {
                                id: appIcon
                                anchors.fill: parent
                                source: {
                                    const r = AppSearch.guessIcon(modelData.icon);
                                    if (r.startsWith("file://"))
                                        return r;
                                    if (r.startsWith("/"))
                                        return "file://" + r;
                                    const p = Quickshell.iconPath(r, false);
                                    return p.length > 0 ? p : "";
                                }
                                smooth: true
                                mipmap: true
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 24
                                font.variableAxes: ({
                                    "FILL": 1
                                })
                                renderType: Text.NativeRendering
                                color: MatugenColors.md3.primary
                                text: "camera"
                                visible: appIcon.status !== Image.Ready
                            }
                            Desaturate {
                                id: desaturatedIcon
                                visible: false
                                anchors.fill: parent
                                source: appIcon
                                desaturation: .5
                            }

                            ColorOverlay {
                                anchors.fill: desaturatedIcon
                                source: desaturatedIcon
                                color: ColorUtils.transparentize(MatugenColors.md3.tertiary, .85)
                                opacity: 1
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            font.pixelSize: 15
                            color: MatugenColors.md3.on_surface
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: appRowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: appList.currentIndex = index
                        onClicked: {
                            root.launchApp(modelData);
                            AppLauncherService.dismiss();
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: !calculator.isCalcMode && appList.contentHeight > appList.height
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
                height: appList.height > 0 ? Math.max(24, (appList.height / appList.contentHeight) * appList.height) : 0
                y: appList.height > 0 ? (appList.contentY / appList.contentHeight) * appList.height : 0
                radius: parent.radius
                color: MatugenColors.md3.on_surface
                opacity: 0.6
            }
        }
    }
}
