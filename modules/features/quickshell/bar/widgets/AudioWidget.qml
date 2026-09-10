import qs.utils
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    Layout.fillWidth: true
    implicitHeight: sink_icon_root.implicitHeight + 4
    Layout.topMargin: -6

    Rectangle {
        anchors { fill: parent; margins: 2 }
        radius: 6
        color: mouse.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.on_background, 0.85) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Row {
        anchors.centerIn: parent
        spacing: 0

        Item {
            id: sink_icon_root
            implicitWidth: sizer.implicitWidth
            implicitHeight: sizer.implicitHeight

            property string targetText: Icons.getAudioSinkIcon(Audio.sink?.name?.startsWith("bluez") ?? false, Audio.sink)
            property color  iconColor: (Audio.sink?.audio?.muted ?? false) ? Globals.barColorLow : Globals.barColorNormal
            property bool   useA: true  // which layer is currently "on top"

            // Invisible sizer drives container dimensions; falls back to the current
            // icon text when targetText is briefly empty (e.g. sink=null during switch).
            Text {
                id: sizer
                visible: false
                text: sink_icon_root.targetText || (sink_icon_root.useA ? icon_a.text : icon_b.text)
                font.pointSize: 17
                font.family: "Material Symbols Rounded"
                font.variableAxes: ({ "FILL": 1 })
                renderType: Text.NativeRendering
            }

            Component.onCompleted: { icon_a.text = targetText; icon_a.opacity = 1 }

            onTargetTextChanged: {
                if (!targetText) return
                if ((useA ? icon_a.text : icon_b.text) === targetText) return
                if (useA) {
                    icon_b.text = targetText
                    crossfadeToB.restart()
                } else {
                    icon_a.text = targetText
                    crossfadeToA.restart()
                }
            }

            ParallelAnimation {
                id: crossfadeToB
                NumberAnimation { target: icon_a; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InOutCubic }
                NumberAnimation { target: icon_b; property: "opacity"; to: 1; duration: 120; easing.type: Easing.InOutCubic }
                onFinished: sink_icon_root.useA = false
            }
            ParallelAnimation {
                id: crossfadeToA
                NumberAnimation { target: icon_b; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InOutCubic }
                NumberAnimation { target: icon_a; property: "opacity"; to: 1; duration: 120; easing.type: Easing.InOutCubic }
                onFinished: sink_icon_root.useA = true
            }

            Text {
                id: icon_a
                anchors.centerIn: parent
                font.pointSize: 17
                font.family: "Material Symbols Rounded"
                font.variableAxes: ({ "FILL": 1 })
                renderType: Text.NativeRendering
                opacity: 0
                color: sink_icon_root.iconColor
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            Text {
                id: icon_b
                anchors.centerIn: parent
                font.pointSize: 17
                font.family: "Material Symbols Rounded"
                font.variableAxes: ({ "FILL": 1 })
                renderType: Text.NativeRendering
                opacity: 0
                color: sink_icon_root.iconColor
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // Mic-muted icon — slides in by expanding a clipping wrapper
        Item {
            id: mic_wrapper
            readonly property bool micMuted: Audio.source?.audio?.muted ?? false
            property real revealScale: 0

            width:  mic_icon.implicitWidth  * revealScale
            height: mic_icon.implicitHeight
            clip: true

            onMicMutedChanged: revealScale = micMuted ? 1 : 0

            Behavior on revealScale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Text {
                id: mic_icon
                font.pointSize: 17
                font.family: "Material Symbols Rounded"
                font.variableAxes: ({ "FILL": 1 })
                renderType: Text.NativeRendering
                text: "mic_off"
                color: Globals.barColorLow
                opacity: mic_wrapper.revealScale

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: DashboardService.show(0)
    }
}
