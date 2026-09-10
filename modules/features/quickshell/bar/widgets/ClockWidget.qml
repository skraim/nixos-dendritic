import qs.services
import qs.utils
import QtQuick
import QtQuick.Layouts

Item {
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true
    implicitHeight: clock.implicitHeight + 18

    Rectangle {
        anchors { fill: parent; margins: 2 }
        radius: 6
        color: mouse.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.on_background, 0.85) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        id: clock
        font.pointSize: 18
        font.family: "B612 Mono"
        font.weight: 600
        horizontalAlignment: Text.AlignHCenter
        text: Time.time.trim().replace(":", "\n")
        lineHeight: .7
        color: MatugenColors.md3.on_background
        style: Text.Outline
        styleColor: MatugenColors.md3.on_surface_variant
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -5
        z: 1
    }

    Item {
        id: date_wrapper
        implicitWidth: date.height
        implicitHeight: date.width
        anchors.left: clock.right
        anchors.verticalCenter: clock.verticalCenter
        anchors.verticalCenterOffset: -2
        anchors.leftMargin: -4

        Text {
            id: date
            font.pointSize: 11
            font.weight: 600
            rotation: 270
            anchors.centerIn: parent
            font.family: "B612 Mono"
            text: Time.date
            color: MatugenColors.md3.secondary
        }
    }

    MouseArea {
        id: mouse
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: DashboardService.show(2)
    }
}
