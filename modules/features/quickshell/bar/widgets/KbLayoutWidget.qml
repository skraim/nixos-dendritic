import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter
    implicitHeight: icon.implicitHeight
    Layout.bottomMargin: -4

    Text {
        id: icon
        anchors.centerIn: parent
        font.pointSize: 17
        text: KbLayout.icon
    }
}
