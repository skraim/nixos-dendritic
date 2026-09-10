import qs.utils
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    Layout.fillWidth: true
    implicitHeight: icon_root.implicitHeight + 4
    Layout.topMargin: -6

    Rectangle {
        anchors { fill: parent; margins: 2 }
        radius: 6
        color: mouse.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.on_background, 0.85) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Item {
        id: icon_root
        anchors.centerIn: parent
        implicitWidth: sizer.implicitWidth
        implicitHeight: sizer.implicitHeight

        property string targetText: Bluetooth.bluetoothEnabled
            ? Bluetooth.bluetoothConnectedCount > 0
                ? "bluetooth_connected"
                : "bluetooth"
            : "bluetooth_disabled"
        property color iconColor: Bluetooth.bluetoothEnabled ? Globals.barColorNormal : Globals.barColorLow
        property bool useA: true

        Text {
            id: sizer
            visible: false
            text: icon_root.targetText
            font.pointSize: 17
            font.family: "Material Symbols Rounded"
            font.variableAxes: ({ "FILL": 1 })
            renderType: Text.NativeRendering
        }

        Component.onCompleted: { icon_a.text = targetText; icon_a.opacity = 1 }

        onTargetTextChanged: {
            if ((useA ? icon_a.text : icon_b.text) === targetText) return
            if (useA) {
                icon_b.text    = targetText
                icon_b.opacity = 0
                crossfadeToB.restart()
            } else {
                icon_a.text    = targetText
                icon_a.opacity = 0
                crossfadeToA.restart()
            }
        }

        ParallelAnimation {
            id: crossfadeToB
            NumberAnimation { target: icon_a; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InOutCubic }
            NumberAnimation { target: icon_b; property: "opacity"; to: 1; duration: 120; easing.type: Easing.InOutCubic }
            onFinished: icon_root.useA = false
        }
        ParallelAnimation {
            id: crossfadeToA
            NumberAnimation { target: icon_b; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InOutCubic }
            NumberAnimation { target: icon_a; property: "opacity"; to: 1; duration: 120; easing.type: Easing.InOutCubic }
            onFinished: icon_root.useA = true
        }

        Text {
            id: icon_a
            anchors.centerIn: parent
            font.pointSize: 17
            font.family: "Material Symbols Rounded"
            font.variableAxes: ({ "FILL": 1 })
            renderType: Text.NativeRendering
            opacity: 0
            color: icon_root.iconColor
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
            color: icon_root.iconColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    Counter {
        text: Bluetooth.bluetoothConnectedCount
        visible: Bluetooth.bluetoothConnectedCount > 0
        anchor: icon_root
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: DashboardService.show(0)
    }
}
