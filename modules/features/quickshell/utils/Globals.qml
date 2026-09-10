pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: globals
    readonly property int componentRadius: 10
    readonly property string slurpArgs: `-b${MatugenColors.md3.background}77 -c${MatugenColors.md3.primary} -w1`

    // Shared blink phase so multiple widgets blink in sync.
    property real blinkOpacity: 1.0
    SequentialAnimation on blinkOpacity {
        loops: Animation.Infinite
        running: true
        PropertyAnimation { from: 1.0; to: 0.3; duration: 500 }
        PropertyAnimation { from: 0.3; to: 1.0; duration: 500 }
    }

    // Bar widget icon color roles
    readonly property color barColorNormal: MatugenColors.md3.on_background
    readonly property color barColorHigh:   MatugenColors.md3.error
    readonly property color barColorLow:    MatugenColors.md3.outline

    readonly property int screenCornerRadius: 10
    readonly property real barOpacity: 1
    // XKB keycodes for digit row (evdev + 8): 1→10, 2→11, … 9→18
    readonly property int digitKeyBase: 10   // nativeScanCode of key '1'

    // Physical evdev scan codes — layout-independent
    readonly property var scanCodes: ({
        'A':38,
        'B':56,
        'C':54,
        'D':40,
        'E':26,
        'F':41,
        'G':42,
        'H':43,
        'I':31,
        'J':44,
        'K':45,
        'L':46,
        'M':58,
        'N':57,
        'O':32,
        'P':33,
        'Q':24,
        'R':27,
        'S':39,
        'T':28,
        'U':30,
        'V':55,
        'W':25,
        'X':53,
        'Y':29,
        'Z':52
    })
}
