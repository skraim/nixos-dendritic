import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.utils

Item {
    id: root

    property string inputText: ""
    readonly property bool isCalcMode: inputText.startsWith("=")
    readonly property string expression: isCalcMode ? inputText.slice(1).trim() : ""
    readonly property var calcResult: {
        if (!isCalcMode)
            return null;
        if (expression.length === 0)
            return "";

        try {
            const result = Function('"use strict"; return (' + expression + ')')();
            if (typeof result === "number" && isFinite(result))
                return parseFloat(result.toPrecision(12)).toString();
            return null;
        } catch (e) {
            return null;
        }
    }

    property string displayedResult: ""

    visible: isCalcMode && displayedResult.length > 0

    function copyResult() {
        if (displayedResult.length > 0 && displayedResult !== "NaN")
            Quickshell.execDetached(["sh", "-c", "printf '%s' " + JSON.stringify(displayedResult) + " | wl-copy"]);
    }

    onCalcResultChanged: {
        if (calcResult !== null && calcResult !== "") {
            calcDebounceTimer.stop();
            displayedResult = calcResult;
        } else if (calcResult === null && isCalcMode) {
            calcDebounceTimer.restart();
        } else {
            calcDebounceTimer.stop();
            displayedResult = "";
        }
    }

    onIsCalcModeChanged: {
        if (!isCalcMode) {
            calcDebounceTimer.stop();
            displayedResult = "";
        }
    }

    Timer {
        id: calcDebounceTimer
        interval: 600
        repeat: false
        onTriggered: root.displayedResult = "NaN"
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 14
        }
        spacing: 14

        Text {
            font.family: "Material Symbols Rounded"
            font.pixelSize: 28
            font.variableAxes: ({
                "FILL": 1
            })
            renderType: Text.NativeRendering
            color: MatugenColors.md3.primary
            opacity: 0.5
            text: "equal"
        }

        Text {
            Layout.fillWidth: true
            text: root.displayedResult
            font.pixelSize: 36
            color: root.displayedResult === "NaN" ? MatugenColors.md3.error : MatugenColors.md3.on_surface
            opacity: root.displayedResult === "NaN" ? 0.5 : 1.0
            elide: Text.ElideRight
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }
    }
}
