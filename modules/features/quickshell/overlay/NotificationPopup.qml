import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import qs.utils
import qs.services

Item {
    id: popup_root

    required property var notification
    width: parent.width + 5
    height: content.height + 30 + 2 * Globals.componentRadius
    z: 1
    clip: false

    // Signal to parent that this component is ready to be destroyed
    signal readyToDestroy

    property bool shifted: false
    property bool wasShifted: false
    onShiftedChanged: if (shifted)
        wasShifted = true

    // Animation properties
    property real slideX: shifted ? 0 : -500  // No slide when shifted, off-screen otherwise
    property real slideY: 0

    transformOrigin: Item.Bottom

    ParallelAnimation {
        id: popInAnimation
        NumberAnimation { target: popup_root; property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { target: popup_root; property: "scale"; from: 0.85; to: 1.0; duration: 250; easing.type: Easing.OutBack }
    }

    ParallelAnimation {
        id: popOutAnimation
        NumberAnimation { target: popup_root; property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
        NumberAnimation { target: popup_root; property: "scale"; from: 1.0; to: 0.85; duration: 150; easing.type: Easing.InBack }
    }

    // Visual transform - does NOT affect layout
    transform: Translate {
        x: popup_root.slideX
        y: popup_root.slideY

        Behavior on x {
            enabled: !popup_root.shifted
            NumberAnimation {
                duration: popup_root.isClosing ? 150 : 400
                easing.type: popup_root.isClosing ? Easing.InCubic : Easing.OutCubic
            }
        }
    }

    // Top-left outer corner — in the transparent space above mainRect
    Shape {
        visible: !popup_root.wasShifted
        anchors.top: parent.top
        anchors.left: parent.left
        width: Globals.componentRadius
        height: Globals.componentRadius
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: MatugenColors.md3.surface
            startX: 0
            startY: Globals.componentRadius
            PathLine {
                x: Globals.componentRadius
                y: Globals.componentRadius
            }
            PathArc {
                x: 0
                y: 0
                radiusX: Globals.componentRadius
                radiusY: Globals.componentRadius
                direction: PathArc.Clockwise
            }
        }
    }

    // Bottom-left outer corner — in the transparent space below mainRect
    Shape {
        visible: !popup_root.wasShifted
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: Globals.componentRadius
        height: Globals.componentRadius
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: MatugenColors.md3.surface
            startX: 0
            startY: 0
            PathLine {
                x: Globals.componentRadius
                y: 0
            }
            PathArc {
                x: 0
                y: Globals.componentRadius
                radiusX: Globals.componentRadius
                radiusY: Globals.componentRadius
                direction: PathArc.Counterclockwise
            }
        }
    }

    Rectangle {
        id: mainRect
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Globals.componentRadius
            bottom: parent.bottom
            bottomMargin: Globals.componentRadius
            leftMargin: popup_root.wasShifted ? 8 : 0
        }
        color: MatugenColors.md3.surface
        radius: 0
        topLeftRadius: popup_root.wasShifted ? Globals.componentRadius : 0
        bottomLeftRadius: popup_root.wasShifted ? Globals.componentRadius : 0
        topRightRadius: Globals.componentRadius
        bottomRightRadius: Globals.componentRadius
        clip: false

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onEntered: popup_root.hovered = true
            onExited: popup_root.hovered = false
            onClicked: function(mouse) {
                if (!notification || isClosing) return;
                if (mouse.button === Qt.MiddleButton) {
                    const actions = notification.notification.actions;
                    const def = actions.find(a => a.identifier === "default");
                    const action = def ?? actions[0] ?? null;
                    if (action) action.invoke();
                }
                closeWithAnimation();
            }
        }

        RowLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 18
            }
            spacing: 15

            // App icon or urgency indicator
            Item {
                id: notif_item
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                Layout.alignment: Qt.AlignVCenter

                // Background rectangle
                Rectangle {
                    anchors.fill: parent
                    color: {
                        if (!notification)
                            return MatugenColors.md3.primary;
                        if (notification.urgency === 2)
                            return MatugenColors.md3.error; // critical
                        if (notification.urgency === 0)
                            return MatugenColors.md3.surface_variant; // low
                        return MatugenColors.md3.primary; // normal - accent color
                    }
                    radius: 8
                    visible: !appIconImage.visible && !notifImage.visible
                }

                // Generic icon fallback
                Text {
                    anchors.centerIn: parent
                    font.pointSize: 24
                    font.family: "Material Symbols Rounded"
                    font.variableAxes: ({
                            "FILL": 1
                        })
                    renderType: Text.NativeRendering
                    text: "notifications"
                    color: MatugenColors.md3.on_primary
                    visible: !appIconImage.visible && !notifImage.visible
                }

                // Rounded container for images
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    clip: true

                    // Notification-specific image (highest priority - contact avatars, etc.)
                    Image {
                        id: notifImage
                        anchors.fill: parent
                        source: {
                            if (!notification || !notification.image) return "";
                            let img = notification.image;
                            if (img.startsWith("image://icon/")) {
                                const iconName = img.substring(13);
                                const p = Quickshell.iconPath(iconName, false);
                                if (p.length > 0 && !p.startsWith("image://")) return p;
                                const fallback = Settings.appIcons[iconName] || Settings.appIcons[iconName.toLowerCase()];
                                if (fallback) {
                                    if (fallback.startsWith("file://") || fallback.startsWith("/")) return fallback;
                                    return "file://" + Quickshell.shellDir + "/" + fallback;
                                }
                                return img;
                            }
                            return img;
                        }
                        sourceSize: Qt.size(56, 56)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // App icon from icon theme (fallback if no notification image)
                    Image {
                        id: appIconImage
                        anchors.fill: parent
                        anchors.margins: 4
                        source: notification && notification.appIcon && !notifImage.visible ? "image://icon/" + notification.appIcon : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: status === Image.Ready
                    }
                }
            }

            // Content
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                // Summary (title)
                Text {
                    Layout.fillWidth: true
                    text: notification ? notification.summary || "" : ""
                    textFormat: Text.StyledText
                    font.bold: true
                    font.pointSize: 12
                    font.family: "DejaVu Sans"
                    color: MatugenColors.md3.on_surface
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                // Body
                Text {
                    Layout.fillWidth: true
                    text: notification ? (notification.body || "").replace(/\n/g, "<br>") : ""
                    textFormat: Text.StyledText
                    font.pointSize: 10
                    font.family: "DejaVu Sans"
                    color: MatugenColors.md3.on_surface
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    visible: notification && notification.body !== ""
                }

                // App name and time
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        text: notification ? notification.appName || "" : ""
                        font.pointSize: 8
                        font.family: "DejaVu Sans"
                        color: MatugenColors.md3.on_surface
                        opacity: 0.7
                    }

                    Text {
                        text: "•"
                        font.pointSize: 8
                        color: MatugenColors.md3.on_surface
                        opacity: 0.7
                    }

                    Text {
                        text: notification ? notification.timeStr || "" : ""
                        font.pointSize: 8
                        font.family: "DejaVu Sans"
                        color: MatugenColors.md3.on_surface
                        opacity: 0.7
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignBottom
                font.pointSize: 20
                font.family: "Material Symbols Rounded"
                font.variableAxes: ({
                        "FILL": 1
                    })
                renderType: Text.NativeRendering
                text: "error"
                color: MatugenColors.md3.error
                opacity: 0.8
                visible: notification && notification.urgency === 2
            }
        }
    }

    function closeWithAnimation() {
        if (isClosing)
            return;
        isClosing = true;
        if (popup_root.shifted) {
            popOutAnimation.start();
        } else {
            popup_root.slideX = -popup_root.width;
        }
        slideOutTimer.start();
    }

    // Hover to pause timeout
    property bool hovered: false

    onHoveredChanged: {
        if (notification && notification.timer) {
            if (hovered) {
                notification.timer.stop();
            } else {
                notification.timer.restart();
            }
        }
    }

    property bool isClosing: false

    // Watch for close request from service (timeout)
    property bool watchRequestClose: notification ? notification.requestClose : false

    onWatchRequestCloseChanged: {
        if (watchRequestClose && !isClosing)
            closeWithAnimation();
    }

    // Watch for cancel close from service (refresh during close animation)
    property bool watchCancelClose: notification ? notification.cancelClose : false

    onWatchCancelCloseChanged: {
        if (watchCancelClose && isClosing) {
            isClosing = false;
            if (notification)
                notification.cancelClose = false;
        }
    }

    Component.onCompleted: {
        popup_root.slideX = 0;  // always break the binding so shifted changes don't affect it
        if (popup_root.shifted) {
            popup_root.opacity = 0;
            popup_root.scale = 0.85;
            popInAnimation.start();
        }
    }

    Timer {
        id: slideOutTimer
        interval: 200  // Slightly longer than slide-out animation (150ms)
        repeat: false
        onTriggered: {
            readyToDestroy();
            if (notification)
                notification.popup = false;
        }
    }

    onIsClosingChanged: {
        if (isClosing) {
            // Prevent timer from running during animation
            if (notification && notification.timer) {
                notification.timer.stop();
            }
        }
    }
}
