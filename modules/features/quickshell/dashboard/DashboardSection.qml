import QtQuick
import QtQuick.Layouts
import qs.utils

ColumnLayout {
    id: root
    required property var win
    property string icon: ""
    property string label: ""
    property string hintKey: ""
    property Component button: null

    default property alias content: _col.data

    Layout.fillWidth: true
    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.bottomMargin: 6
        spacing: 6

        Text {
            font.family: "Material Symbols Rounded"
            font.variableAxes: ({ "FILL": 1 })
            renderType: Text.NativeRendering
            font.pixelSize: 15
            color: MatugenColors.md3.on_surface
            opacity: 0.45
            text: root.icon
        }
        Text {
            text: root.label
            font.pixelSize: 15
            font.letterSpacing: 1
            color: MatugenColors.md3.on_surface
            opacity: 0.45
        }
        Item { Layout.fillWidth: true }

        Loader {
            active: root.button !== null
            sourceComponent: root.button
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            visible: root.hintKey !== ""
            opacity: root.win.tabHintMode ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            width: 16
            height: 16
            radius: 3
            color: MatugenColors.md3.primary
            Text {
                anchors.centerIn: parent
                text: root.hintKey
                font.pixelSize: 9
                font.bold: true
                color: MatugenColors.md3.on_primary
            }
        }
    }

    ColumnLayout {
        id: _col
        Layout.fillWidth: true
        spacing: 0
    }
}
