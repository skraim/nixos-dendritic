import qs.utils
import QtQuick

Item {
    id: root
    property bool isActive: ResourcesUsage.cpuUsage >= .85
    visible: isActive
    implicitHeight: icon.height
    implicitWidth: icon.width

    Text {
        id: icon
        anchors.centerIn: parent
        font.family: "Material Symbols Rounded"
        font.variableAxes: ({ "FILL": 1 })
        renderType: Text.NativeRendering
        font.pointSize: 13
        text: "memory"
        color: Globals.barColorHigh
        opacity: root.isActive ? Globals.blinkOpacity : 0.0
    }
}
