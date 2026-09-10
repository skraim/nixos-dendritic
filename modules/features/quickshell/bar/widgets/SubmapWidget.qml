import qs.utils
import qs.services
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    readonly property bool active: SubmapService.submap !== "default"

    property string displayedSubmap: "resize"

    Timer {
        id: lingerTimer
        interval: 250; repeat: false
    }

    onActiveChanged: {
        if (active) {
            displayedSubmap = SubmapService.submap
            lingerTimer.stop()
        } else {
            lingerTimer.restart()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: active || lingerTimer.running

            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"

            anchors.left: true
            anchors.right: true
            anchors.top: true
            anchors.bottom: true

            Rectangle {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -33
                width: 160; height: 160; radius: 28
                color: ColorUtils.transparentize(MatugenColors.md3.primary, 0.45)

                opacity: active ? 1.0 : 0.0
                scale:   active ? 1.0 : 0.85
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 96
                    color: MatugenColors.md3.on_background
                    text: displayedSubmap === "resize" ? "resize" : "drag_pan"
                }
            }
        }
    }
}
