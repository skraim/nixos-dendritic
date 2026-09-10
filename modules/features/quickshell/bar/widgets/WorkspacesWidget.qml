import qs.utils
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

ColumnLayout {
    Layout.fillWidth: true
    Layout.topMargin: 7
    spacing: 5

    Repeater {
        model: ScriptModel {
            objectProp: "name"
            values: {
                const workspaces = [...Hyprland.workspaces.values];

                let result = Array.from({ length: 10 }, (_, i) => ({
                    name: String(i + 1)
                }));

                for (const ws of workspaces) {
                    const num = parseInt(ws.name, 10);
                    if (num >= 1 && num <= 10) {
                        result[num - 1] = Object.assign({}, result[num - 1], ws);
                    } else {
                        result.push(ws);
                    }
                }

                return result;
            }
        }

        Item {
            id: ws_row
            required property var modelData
            required property var index
            visible: ws_row.shouldShow
            implicitWidth: ws_row_inner.width
            implicitHeight: 0
            clip: !ws_row.shouldShow
            Layout.bottomMargin: 0

            readonly property bool isFocused: !!modelData.id && (
                modelData.name?.startsWith("special")
                    ? [...Hyprland.monitors.values].some(m => m.focused && m.lastIpcObject?.specialWorkspace?.id === modelData.id)
                    : !!modelData.focused
            )

            readonly property bool isActiveOnOtherMonitor: {
                if (ws_row.isFocused || !modelData.id) return false;
                return [...Hyprland.monitors.values].some(m => m.lastIpcObject?.activeWorkspace?.id === modelData.id);
            }
            property var appEntries: []
            property string appSignature: ""
            property int appClassCount: 0
            property string focusedAppClass: ""

            readonly property bool hasApps: ws_row.appClassCount > 0
            readonly property bool shouldShow: ws_row.isFocused || ws_row.isActiveOnOtherMonitor || ws_row.hasApps

            function syncApps() {
                if (!ws_row.modelData.id) {
                    if (ws_row.appSignature !== "" || ws_row.focusedAppClass !== "") {
                        ws_row.appEntries = [];
                        ws_row.appSignature = "";
                        ws_row.appClassCount = 0;
                        ws_row.focusedAppClass = "";
                    }
                    return;
                }

                const rawApps = HyprlandData.workspaceApps(ws_row.modelData.id);
                const counts = rawApps.map(app => app.lastIpcObject?.["class"]).filter(c => c).reduce((acc, appClass) => {
                    acc.set(appClass, (acc.get(appClass) || 0) + 1);
                    return acc;
                }, new Map());

                const biggestClass = HyprlandData.biggestWindowForWorkspace(ws_row.modelData.id)?.lastIpcObject?.["class"] ?? "";
                const entries = [...counts.entries()].sort((a, b) => {
                    if (a[0] === biggestClass && b[0] !== biggestClass)
                        return -1;
                    if (b[0] === biggestClass && a[0] !== biggestClass)
                        return 1;
                    return b[1] - a[1];
                }).slice(0, 2);
                const signature = JSON.stringify(entries);

                if (ws_row.appSignature !== signature) {
                    ws_row.appEntries = entries;
                    ws_row.appSignature = signature;
                    ws_row.appClassCount = counts.size;
                } else if (ws_row.appClassCount !== counts.size) {
                    ws_row.appClassCount = counts.size;
                }

                ws_row.focusedAppClass = rawApps.find(app => app.lastIpcObject?.focusHistoryID == 0)?.lastIpcObject?.["class"] ?? "";
            }

            function shouldSyncAppsForHyprlandEvent(eventName) {
                return [
                    "activewindow",
                    "activewindowv2",
                    "openwindow",
                    "closewindow",
                    "movewindow",
                    "movewindowv2"
                ].includes(eventName);
            }

            Component.onCompleted: ws_row.syncApps()

            onModelDataChanged: ws_row.syncApps()

            Connections {
                target: Hyprland

                function onRawEvent(event: HyprlandEvent): void {
                    if (ws_row.shouldSyncAppsForHyprlandEvent(event.name))
                        Qt.callLater(ws_row.syncApps);
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 100
                }
            }

            states: [
                State {
                    name: "visible"
                    when: ws_row.shouldShow
                    PropertyChanges {
                        target: ws_row
                        implicitHeight: ws_row_inner.implicitHeight
                    }
                },
                State {
                    name: "hidden"
                    when: !ws_row.shouldShow
                    PropertyChanges {
                        target: ws_row
                        implicitHeight: 0
                    }
                }
            ]

            MouseArea {
                id: mouse
                hoverEnabled: true
                enabled: ws_row.shouldShow
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (ws_row.modelData.name.startsWith("special")) {
                        Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"\")");
                        return;
                    }

                    Hyprland.dispatch(`hl.dsp.focus({ workspace = ${ws_row.modelData.name} })`);
                }
            }

            Rectangle {
                id: ws_row_rect
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 2
                opacity: 0
                color: MatugenColors.md3.tertiary_container
                width: ws_row_inner.width

                states: [
                    State {
                        name: "focused"
                        when: ws_row.isFocused && ws_row.hasApps

                        PropertyChanges {
                            ws_row_rect {
                                opacity: 1
                            }
                        }
                    },
                    State {
                        name: "active"
                        when: ws_row.isActiveOnOtherMonitor

                        PropertyChanges {
                            ws_row_rect {
                                opacity: 0.55
                            }
                        }
                    }
                ]

                transitions: Transition {
                    from: "*"
                    to: "focused"
                    SequentialAnimation {
                        PauseAnimation {
                            duration: 100
                        }
                        NumberAnimation {
                            properties: "opacity"
                            duration: 150
                        }
                    }
                }
            }

            Rectangle {
                id: urgent_rect
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 2
                opacity: 0
                color: MatugenColors.md3.error
                width: ws_row_inner.width
                z: 1

                states: State {
                    name: "urgent"
                    when: !!ws_row.modelData.urgent
                    PropertyChanges {
                        urgent_rect { opacity: 0.4 }
                    }
                }

                transitions: Transition {
                    from: "*"
                    to: "urgent"
                    SequentialAnimation {
                        loops: Animation.Infinite

                        PropertyAnimation {
                            target: urgent_rect
                            property: "opacity"
                            from: .1
                            to: .4
                            duration: 300
                        }
                        PropertyAnimation {
                            target: urgent_rect
                            property: "opacity"
                            from: .4
                            to: .1
                            duration: 600
                        }
                    }
                }
            }

            RowLayout {
                id: ws_row_inner
                spacing: 0

                Item {
                    id: label_wrapper
                    implicitWidth: 10
                    implicitHeight: ws_row.shouldShow ? 20 : 0
                    Layout.preferredWidth: 30

                    Rectangle {
                        id: hovering_rect
                        anchors.fill: parent
                        topRightRadius: 5
                        bottomRightRadius: 5
                        topLeftRadius: 2
                        bottomLeftRadius: 2
                        color: mouse.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.tertiary, .75) : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    Rectangle {
                        id: rect
                        topRightRadius: 5
                        bottomRightRadius: 5
                        topLeftRadius: 2
                        bottomLeftRadius: 2
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: MatugenColors.md3.tertiary

                        states: [
                            State {
                                name: "focused"
                                when: ws_row.isFocused

                                PropertyChanges {
                                    rect {
                                        height: label_wrapper.height
                                        width: label_wrapper.width
                                        opacity: 1
                                    }
                                }
                            },
                        ]
                        transitions: Transition {
                            SequentialAnimation {
                                NumberAnimation {
                                    properties: "width"
                                    duration: 100
                                }
                                NumberAnimation {
                                    properties: "height"
                                    duration: 100
                                }
                            }
                        }
                    }

                    Text {
                        id: label
                        visible: ws_row.shouldShow
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.name.startsWith("special") ? "" : modelData.name
                        color: ws_row.isFocused ? MatugenColors.md3.on_primary : MatugenColors.md3.secondary

                        font {
                            family: "Play"
                            pointSize: 13
                            weight: 600
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                }

                WrapperItem {
                    Layout.preferredWidth: 35

                    RowLayout {
                        id: apps
                        visible: ws_row.hasApps
                        spacing: -7

                        Repeater {
                            model: ws_row.appEntries

                            delegate: Item {
                                id: app
                                required property var modelData
                                required property int index

                                property var appIconSource: {
                                    const r = AppSearch.guessIcon(modelData[0])
                                    return (r.startsWith("/") || r.startsWith("file://"))
                                        ? r
                                        : Quickshell.iconPath(r, "image-missing")
                                }

                                Layout.alignment: ws_row.appClassCount > 1 ? Qt.AlignLeft : Qt.AlignHCenter
                                implicitHeight: app_icon.height
                                implicitWidth: app_icon.width
                                opacity: 1

                                NumberAnimation {
                                    id: fadeInAnimation
                                    target: app
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 150
                                }

                                Component.onCompleted: {
                                    if (modelData[1] == 1) {
                                        fadeInAnimation.start();
                                    }
                                }

                                IconImage {
                                    id: app_icon
                                    source: parent.appIconSource
                                    implicitSize: 17
                                    z: parent.index
                                }

                                Desaturate {
                                    id: desaturatedIcon
                                    visible: false
                                    anchors.fill: parent
                                    source: app_icon
                                    desaturation: .7
                                }

                                ColorOverlay {
                                    id: color_overlay
                                    anchors.fill: desaturatedIcon
                                    source: desaturatedIcon
                                    color: ColorUtils.transparentize(MatugenColors.md3.tertiary, .75)
                                    opacity: 1

                                    states: State {
                                        name: "focused"
                                        when: ws_row.focusedAppClass === modelData[0]

                                        PropertyChanges {
                                            color_overlay {
                                                opacity: 0
                                            }
                                        }
                                    }

                                    transitions: Transition {
                                        NumberAnimation {
                                            properties: "opacity"
                                            duration: 150
                                        }
                                    }
                                }

                                Counter {
                                    id: counter
                                    text: modelData[1]
                                    visible: modelData[1] > 1
                                    anchor: app_icon
                                    height: 12
                                    fontSize: 8
                                    anchors.topMargin: -4
                                    anchors.rightMargin: -3
                                }

                                Desaturate {
                                    id: desaturatedCounter
                                    visible: modelData[1] > 1 && ws_row.focusedAppClass !== modelData[0]
                                    anchors.fill: counter
                                    source: counter
                                    desaturation: .4
                                    z: index + 2
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
