import qs.utils
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    Layout.fillWidth: true
    implicitHeight: icon_root.implicitHeight + 4

    Rectangle {
        anchors { fill: parent; margins: 2 }
        radius: 6
        color: mouse.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.on_background, 0.85) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        id: icon_root
        font.pointSize: 17
        anchors.centerIn: parent
        font.family: "Material Symbols Rounded"
        font.variableAxes: ({ "FILL": 1 })
        renderType: Text.NativeRendering
        text: "security"
        color: Globals.barColorNormal
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: DashboardService.show(0)
    }
}
