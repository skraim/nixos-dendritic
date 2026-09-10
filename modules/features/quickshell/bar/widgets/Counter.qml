import qs.utils
import QtQuick
import Quickshell.Widgets

ClippingWrapperRectangle {
    id: root
    property int text
    property var anchor
    property int fontSize
    color: MatugenColors.md3.error
    implicitWidth: counter.implicitWidth + 7
    height: 13
    radius: 10
    z: 1

    anchors {
        top: anchor.top
        right: anchor.right
        topMargin: -1
        rightMargin: -5
    }

    Text {
        id: counter
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.text > 99 ? "99+" : root.text
        color: MatugenColors.md3.on_error
        font.pointSize: root.fontSize || 9
        font.weight: 700
        font.family: "Play"
    }
}
