import qs.utils
import qs.services
import qs.bar.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Scope {
    // ── Tray KB-mode dismiss overlay (secondary monitors) ─────────────────
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusiveZone: -1
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            visible: BarNavigationService.trayMenuKbOpen
            Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: BarNavigationService.closeTrayNav()
            }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar_root
            property var modelData
            property color black_color: MatugenColors.md3.shadow
            color: "transparent"
            screen: modelData
            implicitWidth: 65 + Globals.componentRadius
            exclusiveZone: 65
            margins.left: -1

            property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(modelData)
            property bool hasFullscreen: HyprlandData.fullscreenOnMonitor(hyprMonitor)

            property bool dashOverlay: false
            Timer {
                id: dashCloseDelay
                interval: 220
                onTriggered: bar_root.dashOverlay = false
            }
            function syncDashOverlay() {
                if (DashboardService.visible && DashboardService.screen !== null && Hyprland.monitorFor(DashboardService.screen)?.id === bar_root.hyprMonitor?.id) {
                    dashCloseDelay.stop();
                    bar_root.dashOverlay = true;
                } else if (!DashboardService.visible) {
                    dashCloseDelay.restart();
                }
            }
            Connections {
                target: DashboardService
                function onScreenChanged() {
                    bar_root.syncDashOverlay();
                }
                function onVisibleChanged() {
                    bar_root.syncDashOverlay();
                }
            }

            WlrLayershell.layer: (bar_root.dashOverlay && !hasFullscreen) ? WlrLayer.Overlay : WlrLayer.Top

            anchors {
                top: true
                left: true
                bottom: true
            }

            WrapperItem {
                visible: !bar_root.hasFullscreen
                anchors {
                    top: parent.top
                    left: parent.left
                }

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 0
                    radius: 9
                    samples: 17
                    color: bar_root.black_color
                }
                // topMargin: -23
                z: 2

                ColumnLayout {
                    spacing: 0

                    DistroWidget {
                        id: distro
                        z: 1
                    }

                    WorkspacesWidget {
                        id: workspases
                        z: 1
                    }

                    Rectangle {
                        id: bar_top_bg
                        anchors.top: parent.top
                        anchors.left: parent.left
                        color: MatugenColors.md3.background
                        topLeftRadius: 0
                        bottomRightRadius: Globals.componentRadius
                        opacity: Globals.barOpacity
                        height: Math.max(modelData.height / 3, distro.height + workspases.height)
                        width: bar_root.width - Globals.componentRadius

                        // layer.enabled: true
                        // layer.effect: DropShadow {
                        //     horizontalOffset: 0
                        //     verticalOffset: 0
                        //     radius: 9
                        //     samples: 17
                        //     color: "#000"
                        // }
                    }

                    Shape {
                        anchors.left: bar_top_bg.right
                        anchors.top: bar_top_bg.top
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false

                        // layer.enabled: true
                        // layer.effect: DropShadow {
                        //     horizontalOffset: 0
                        //     verticalOffset: 0
                        //     radius: 9
                        //     samples: 17
                        //     color: "#000"
                        // }

                        ShapePath {
                            property color bg_color: Qt.color(MatugenColors.md3.background)
                            strokeWidth: -1
                            fillColor: Qt.rgba(bg_color.r, bg_color.g, bg_color.b, Globals.barOpacity)
                            // startY: 23

                            PathLine {
                                relativeX: Globals.componentRadius
                                relativeY: 0
                            }

                            PathArc {
                                relativeX: -Globals.componentRadius
                                relativeY: Globals.componentRadius
                                radiusX: Globals.componentRadius
                                radiusY: Globals.componentRadius
                                direction: PathArc.Counterclockwise
                            }
                        }
                    }

                    Shape {
                        anchors.top: bar_top_bg.bottom
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false

                        // layer.enabled: true
                        // layer.effect: DropShadow {
                        //     horizontalOffset: 0
                        //     verticalOffset: 0
                        //     radius: 9
                        //     samples: 17
                        //     color: "#000"
                        // }

                        ShapePath {
                            property color bg_color: Qt.color(MatugenColors.md3.background)
                            strokeWidth: -1
                            fillColor: Qt.rgba(bg_color.r, bg_color.g, bg_color.b, Globals.barOpacity)

                            PathLine {
                                relativeX: Globals.componentRadius
                            }

                            PathArc {
                                relativeX: -Globals.componentRadius
                                relativeY: Globals.componentRadius
                                radiusX: Globals.componentRadius
                                radiusY: Globals.componentRadius
                                direction: PathArc.Counterclockwise
                            }
                        }
                    }
                }
            }

            WrapperItem {
                width: 5
                height: bar_root.modelData.height / 3
                x: -5
                z: 1
                visible: !bar_root.hasFullscreen

                anchors {
                    verticalCenter: parent.verticalCenter
                }

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 0
                    radius: 9
                    samples: 17
                    color: bar_root.black_color
                }

                Rectangle {
                    anchors.fill: parent
                    color: MatugenColors.md3.background
                }
            }

            Item {
                visible: !bar_root.hasFullscreen
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                }
                width: bar_root.width
                height: bar_bottom_bg.height + Globals.componentRadius

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 0
                    radius: 9
                    samples: 17
                    color: bar_root.black_color
                }
                z: 2

                Rectangle {
                    id: bar_bottom_bg
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                    }
                    color: MatugenColors.md3.background
                    topLeftRadius: 0
                    topRightRadius: Globals.componentRadius
                    opacity: Globals.barOpacity
                    height: Math.max(modelData.height / 3, innerCol.implicitHeight)
                    width: bar_root.width - Globals.componentRadius

                    // Decorative corner shapes — rendered outside bar_bottom_bg bounds
                    // (Rectangle.clip is false by default)
                    Shape {
                        id: bbar_top_rcorner
                        y: -Globals.componentRadius
                        width: Globals.componentRadius
                        height: Globals.componentRadius
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false
                        ShapePath {
                            property color bg_color: Qt.color(MatugenColors.md3.background)
                            strokeWidth: -1
                            fillColor: Qt.rgba(bg_color.r, bg_color.g, bg_color.b, Globals.barOpacity)
                            startY: Globals.componentRadius
                            PathLine {
                                relativeX: Globals.componentRadius
                                relativeY: 0
                            }
                            PathArc {
                                relativeX: -Globals.componentRadius
                                relativeY: -Globals.componentRadius
                                radiusX: Globals.componentRadius
                                radiusY: Globals.componentRadius
                                direction: PathArc.Clockwise
                            }
                        }
                    }

                    Shape {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.right
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false
                        ShapePath {
                            property color bg_color: Qt.color(MatugenColors.md3.background)
                            strokeWidth: -1
                            fillColor: Qt.rgba(bg_color.r, bg_color.g, bg_color.b, Globals.barOpacity)
                            startY: Globals.componentRadius
                            PathLine {
                                relativeX: Globals.componentRadius
                                relativeY: 0
                            }
                            PathArc {
                                relativeX: -Globals.componentRadius
                                relativeY: -Globals.componentRadius
                                radiusX: Globals.componentRadius
                                radiusY: Globals.componentRadius
                                direction: PathArc.Clockwise
                            }
                        }
                    }

                    // Content — drives bar_bottom_bg height via implicitHeight
                    ColumnLayout {
                        id: innerCol
                        anchors.bottom: parent.bottom
                        width: parent.width
                        spacing: 5

                        Item {
                            id: resources_alerts
                            Layout.fillWidth: true
                            readonly property bool anyVisible: cpu_w.visible || mem_w.visible || bat_w.visible
                            Layout.topMargin: anyVisible ? 15 : 0
                            Layout.bottomMargin: anyVisible ? 5 : 0
                            implicitHeight: anyVisible ? 28 : 0
                            clip: true

                            Behavior on implicitHeight {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on Layout.topMargin {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on Layout.bottomMargin {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors {
                                    fill: parent
                                    margins: 2
                                }
                                radius: 6
                                color: resources_mouse.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.on_background, 0.85) : "transparent"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 1

                                CpuWidget {
                                    id: cpu_w
                                }
                                MemoryWidget {
                                    id: mem_w
                                }
                                BatteryWidget {
                                    id: bat_w
                                }
                            }

                            MouseArea {
                                id: resources_mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: cpu_w.visible || mem_w.visible || bat_w.visible
                                cursorShape: Qt.PointingHandCursor
                                onClicked: DashboardService.show(0)
                            }
                        }

                        AudioWidget {
                            id: audio
                        }
                        BluetoothWidget {
                            id: bluetooth
                        }

                        Item {
                            id: network_wrapper
                            Layout.fillWidth: true
                            Layout.topMargin: -6
                            visible: implicitHeight > 0
                            implicitHeight: 0
                            clip: true

                            Component.onCompleted: {
                                if (!Network.ethernet) {
                                    implicitHeight = network.implicitHeight;
                                    network.opacity = 1;
                                }
                            }
                            Connections {
                                target: Network
                                function onEthernetChanged() {
                                    if (!Network.ethernet)
                                        network_show.start();
                                    else
                                        network_hide.start();
                                }
                            }
                            SequentialAnimation {
                                id: network_show
                                NumberAnimation {
                                    target: network_wrapper
                                    property: "implicitHeight"
                                    to: network.implicitHeight
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: network
                                    property: "opacity"
                                    to: 1
                                    duration: 150
                                }
                            }
                            SequentialAnimation {
                                id: network_hide
                                NumberAnimation {
                                    target: network
                                    property: "opacity"
                                    to: 0
                                    duration: 150
                                }
                                NumberAnimation {
                                    target: network_wrapper
                                    property: "implicitHeight"
                                    to: 0
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            NetworkWidget {
                                id: network
                                width: parent.width
                                opacity: 0
                            }
                        }

                        NotificationWidget {
                            id: notification
                        }

                        Item {
                            id: vpn_wrapper
                            Layout.fillWidth: true
                            Layout.topMargin: -6
                            visible: implicitHeight > 0
                            implicitHeight: 0
                            clip: true

                            Component.onCompleted: {
                                if (Network.vpnConnected) {
                                    implicitHeight = vpn.implicitHeight;
                                    vpn.opacity = 1;
                                }
                            }
                            Connections {
                                target: Network
                                function onVpnConnectedChanged() {
                                    if (Network.vpnConnected)
                                        vpn_show.start();
                                    else
                                        vpn_hide.start();
                                }
                            }
                            SequentialAnimation {
                                id: vpn_show
                                NumberAnimation {
                                    target: vpn_wrapper
                                    property: "implicitHeight"
                                    to: vpn.implicitHeight
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: vpn
                                    property: "opacity"
                                    to: 1
                                    duration: 150
                                }
                            }
                            SequentialAnimation {
                                id: vpn_hide
                                NumberAnimation {
                                    target: vpn
                                    property: "opacity"
                                    to: 0
                                    duration: 150
                                }
                                NumberAnimation {
                                    target: vpn_wrapper
                                    property: "implicitHeight"
                                    to: 0
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            VpnWidget {
                                id: vpn
                                width: parent.width
                                opacity: 0
                            }
                        }

                        SystemTrayWidget {
                            id: tray
                            barScreen: bar_root.modelData
                        }

                        KbLayoutWidget {
                            id: kb_layout
                        }
                        ClockWidget {
                            id: clock
                        }
                    }
                }
            }
        }
    }
}
