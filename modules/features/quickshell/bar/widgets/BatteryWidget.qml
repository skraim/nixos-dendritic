import qs.utils
import qs.services
import QtQuick

Item {
    id: root
    property bool isActive: Battery.percentage < .5 || Battery.percentage < .9 && Battery.isCharging
    visible: isActive
    implicitHeight: icon.height
    implicitWidth: icon.width

    Text {
        id: icon
        opacity: root.isActive ? Globals.blinkOpacity : 0.0
        font.pointSize: 13
        font.family: "Material Symbols Rounded"
        font.variableAxes: ({ "FILL": 1 })
        renderType: Text.NativeRendering
        font.letterSpacing: -6
        text: Icons.getBatteryIcon(Battery.percentage) + Icons.getBatteryStateIcon(Battery.chargeState)
        color: Globals.barColorHigh
    }
}
