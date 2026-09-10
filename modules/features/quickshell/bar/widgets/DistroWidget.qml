import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    Layout.topMargin: 3
    Layout.alignment: Qt.AlignCenter
    implicitHeight: 42
    implicitWidth: 42

    Image {
        id: nixos_img
        anchors.centerIn: parent
        width: 37; height: 37
        source: Quickshell.shellDir + "/" + Settings.distroIcon
        sourceSize: Qt.size(width, height)
    }

    MouseArea {
        anchors { fill: parent; margins: -10 }
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppLauncherService.toggle()
    }
}
