import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.utils
import qs.services
import Qt5Compat.GraphicalEffects

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        ShellRoot {
            id: shell_root
            property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)

            property string lastWindowAddress: ""
            property int lastWindowMonitor: -1
            property string currentAppName: ""

            property var localActiveWindowData: HyprlandData.activeWindowData

            onLocalActiveWindowDataChanged: {
                updateActiveWindow();
            }

            Connections {
                target: shell_root.localActiveWindowData
                function onLastIpcObjectChanged() { shell_root.updateActiveWindow() }
                function onMonitorChanged()       { shell_root.updateActiveWindow() }
            }

            function updateActiveWindow() {
                if (!localActiveWindowData || !localActiveWindowData.address) {
                    if (popup.isShown) {
                        popup.hide();
                    }
                    return;
                }

                let newAddress = localActiveWindowData.address;
                let windowMonitor = localActiveWindowData.monitor?.id ?? -1;

                if (windowMonitor !== shell_root.monitor.id) {
                    if (popup.isShown) {
                        popup.hide();
                    }
                    shell_root.lastWindowAddress = "";
                    shell_root.lastWindowMonitor = -1;
                    shell_root.currentAppName = "";
                    return;
                }

                // Window is on this monitor
                let appName = ActiveWindowMapper.getAppName(localActiveWindowData.lastIpcObject?.["class"]);
                let windowTitle = localActiveWindowData.title || "";

                if (!appName || appName === "undefined") {
                    if (popup.isShown) {
                        popup.hide();
                    }
                    return;
                }

                // Check if window or monitor changed
                let windowChanged = (newAddress !== shell_root.lastWindowAddress);
                let monitorChanged = (windowMonitor !== shell_root.lastWindowMonitor);

                // Only proceed if something actually changed
                if (!windowChanged && !monitorChanged) {
                    // Same window on same monitor, nothing to do
                    return;
                }

                shell_root.lastWindowAddress = newAddress;
                shell_root.lastWindowMonitor = windowMonitor;
                shell_root.currentAppName = appName;
                popup.displayAppName = appName;
                popup.displayWindowTitle = windowTitle;

                // Show or update popup based on its current state
                if (!popup.isShown) {
                    // Popup is hidden, slide it in
                    popup.show();
                } else {
                    // Popup is visible, just update content
                    popup.updateContent(appName, windowTitle);
                }
            }

            PanelWindow {
                id: popup
                screen: shell_root.modelData
                color: "transparent"
                width: 450 + (Globals.componentRadius * 2)
                height: 57
                // visible: isShown
                exclusiveZone: 0
                margins.top: -1

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                mask: Region {
                    x: container.x
                    y: container.y
                    width: container.width
                    height: container.height
                }

                anchors {
                    top: true
                    left: true
                }

                margins {
                    left: (shell_root.modelData.width - width) / 2 - 65
                }

                property bool isShown: false
                property string displayAppName: ""
                property string displayWindowTitle: ""

                function show() {
                    container.y = -container.height;
                    // visible = true;
                    isShown = true;
                    slideInAnimation.start();
                    hideTimer.restart();
                }

                function updateContent(appName, windowTitle) {
                    displayAppName = appName;
                    displayWindowTitle = windowTitle;
                    if (slideOutAnimation.running) {
                        slideOutAnimation.stop();
                        slideInAnimation.start();
                    }
                    hideTimer.restart();
                }

                function hide() {
                    slideOutAnimation.start();
                }

                onIsShownChanged: {
                    if (!isShown) {
                        hideDelayTimer.start();
                    }
                }

                Timer {
                    id: hideDelayTimer
                    interval: 300
                    repeat: false
                    onTriggered: {
                        if (!popup.isShown) {
                            // popup.visible = false;
                        }
                    }
                }

                Timer {
                    id: hideTimer
                    interval: 2000
                    repeat: false
                    onTriggered: popup.hide()
                }
                // WrapperItem {
                //     Layout.fillWidth: true
                //     Layout.fillHeight: true
                //     Layout.
                //     layer.enabled: true
                //     layer.effect: DropShadow {
                //         horizontalOffset: 0
                //         verticalOffset: 0
                //         radius: 9
                //         samples: 17
                //         color: MatugenColors.md3.shadow
                //     }

                Item {
                    anchors.fill: parent

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 9
                        samples: 17
                        color: MatugenColors.md3.shadow
                    }

                    Shape {
                        anchors.top: container.top
                        anchors.right: container.left
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false

                        ShapePath {
                            property color bg_color: Qt.color(MatugenColors.md3.surface)
                            strokeWidth: -1
                            fillColor: Qt.rgba(bg_color.r, bg_color.g, bg_color.b, Globals.barOpacity)

                            PathLine {
                                relativeX: Globals.screenCornerRadius
                            }

                            PathLine {
                                relativeX: 0
                                relativeY: Globals.screenCornerRadius
                            }

                            PathArc {
                                relativeX: -Globals.screenCornerRadius
                                relativeY: -Globals.screenCornerRadius
                                radiusX: Globals.screenCornerRadius
                                radiusY: Globals.screenCornerRadius
                                direction: PathArc.Counterclockwise
                            }
                        }
                    }

                    Shape {
                        anchors.top: container.top
                        anchors.left: container.right
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false

                        ShapePath {
                            property color bg_color: Qt.color(MatugenColors.md3.surface)
                            strokeWidth: -1
                            fillColor: Qt.rgba(bg_color.r, bg_color.g, bg_color.b, Globals.barOpacity)
                            startX: -1

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

                    Rectangle {
                        id: container
                        x: Globals.componentRadius
                        y: -height
                        width: parent.width - (Globals.componentRadius * 2)
                        height: parent.height - 7
                        color: MatugenColors.md3.surface
                        opacity: Globals.barOpacity

                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: Globals.componentRadius
                        bottomRightRadius: Globals.componentRadius
                    // Mouse area to detect hover and hide popup
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            if (popup.isShown) {
                                popup.hide();
                            }
                        }
                    }

                    // Initial slide in animation
                    NumberAnimation {
                        id: slideInAnimation
                        target: container
                        property: "y"
                        to: 0
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                    // Slide out animation
                    NumberAnimation {
                        id: slideOutAnimation
                        target: container
                        property: "y"
                        to: -container.height - 5
                        duration: 250
                        easing.type: Easing.InCubic
                        onFinished: {
                            popup.isShown = false;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            width: 3
                            Layout.fillHeight: true
                            color: MatugenColors.md3.secondary
                            radius: 1.5
                        }

                        Row {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0
                            clip: true

                            Text {
                                id: appNameText
                                text: popup.displayAppName
                                font.pointSize: 11
                                font.weight: Font.Bold
                                color: MatugenColors.md3.on_surface
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                id: separatorText
                                text: " - "
                                font.pointSize: 11
                                color: MatugenColors.md3.on_surface
                                verticalAlignment: Text.AlignVCenter
                                // visible: popup.displayWindowTitle !== ""
                            }

                            Text {
                                id: windowTitleText
                                text: popup.displayWindowTitle
                                font.pointSize: 11
                                color: MatugenColors.md3.on_surface
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                width: Math.max(0, parent.width - appNameText.width - separatorText.width - 5)
                                // visible: popup.displayWindowTitle !== ""
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: Globals.componentRadius
                        bottomRightRadius: Globals.componentRadius
                    }
                }
                } // Item (shadow wrapper)
            }
        }
    }
}
