import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.utils
import Qt5Compat.GraphicalEffects

Scope {
    id: osdScope
    readonly property bool dashboardControlsOpen: DashboardService.visible && DashboardService.currentTab === 0

    // ── Shared state ─────────────────────────────────────────────────────
    property bool   osdVisible: false
    property string osdMode:    "speaker"  // "speaker" | "mic" | "brightness"

    readonly property real displayVolume: {
        if (osdMode === "brightness") return BrightnessOSDService.currentBrightness / 100.0
        if (osdMode === "mic")        return Audio.source?.audio?.muted ? 0 : (Audio.source?.audio?.volume ?? 0)
        return VolumeOSDService.isMuted ? 0 : VolumeOSDService.currentVolume
    }

    readonly property color displayColor: {
        if (osdMode === "brightness") return MatugenColors.md3.tertiary
        const muted = osdMode === "speaker" ? VolumeOSDService.isMuted : (Audio.source?.audio?.muted ?? false)
        if (muted) return MatugenColors.md3.error
        return osdMode === "speaker" ? MatugenColors.md3.primary : MatugenColors.md3.secondary
    }

    readonly property string displayIcon: {
        if (osdMode === "brightness") return "brightness_high"
        if (osdMode === "mic")        return Audio.source?.audio?.muted ? "mic_off" : "\ue029"
        return VolumeOSDService.isMuted ? "volume_off" : "volume_up"
    }

    // ── Show/hide timers ─────────────────────────────────────────────────
    Timer {
        id: osdHideTimer
        interval: 2000; repeat: false
        onTriggered: { osdLingerTimer.restart(); osdVisible = false }
    }
    Timer { id: osdLingerTimer; interval: 250; repeat: false }

    function triggerOSD(mode) {
        osdMode    = mode
        osdVisible = true
        osdHideTimer.restart()
    }

    // ── Speaker events ───────────────────────────────────────────────────
    Connections {
        target: VolumeOSDService
        function onCurrentVolumeChanged() { if (!dashboardControlsOpen) triggerOSD("speaker") }
        function onIsMutedChanged()       { if (!dashboardControlsOpen) triggerOSD("speaker") }
    }

    // ── Mic events ───────────────────────────────────────────────────────
    Connections {
        target: Audio.source?.audio
        function onVolumeChanged() { if (!dashboardControlsOpen) triggerOSD("mic") }
        function onMutedChanged()  { if (!dashboardControlsOpen) triggerOSD("mic") }
    }

    // ── Brightness events ─────────────────────────────────────────────────
    Connections {
        target: BrightnessOSDService
        function onShowRequested() { triggerOSD("brightness") }
    }

    // ── Icon cross-fade on mode switch ───────────────────────────────────
    property real   iconOpacity: 1.0
    property real   iconScale:   1.0
    property string shownIcon:   ""   // updated only at opacity=0 to avoid flicker

    Component.onCompleted: shownIcon = displayIcon
    onDisplayIconChanged:  { if (!iconSwitchAnim.running) shownIcon = displayIcon }
    onOsdModeChanged:      iconSwitchAnim.restart()

    SequentialAnimation {
        id: iconSwitchAnim
        ParallelAnimation {
            NumberAnimation { target: osdScope; property: "iconOpacity"; to: 0.0; duration: 100; easing.type: Easing.InCubic }
            NumberAnimation { target: osdScope; property: "iconScale";   to: 0.5; duration: 100; easing.type: Easing.InCubic }
        }
        ScriptAction { script: osdScope.shownIcon = osdScope.displayIcon }
        ParallelAnimation {
            NumberAnimation { target: osdScope; property: "iconOpacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: osdScope; property: "iconScale";   to: 1.0; duration: 180; easing.type: Easing.OutBack }
        }
    }

    // ── Brightness setter process ─────────────────────────────────────────
    Process {
        id: brightnessSetProc
        running: false
    }

    // ── OSD Window ───────────────────────────────────────────────────────
    LazyLoader {
        loading: osdVisible || osdLingerTimer.running

        PanelWindow {
            exclusiveZone: 0
            height: osdContent.height
            visible: osdVisible || osdLingerTimer.running
            anchors.left: true
            margins.left: -65
            width: 80

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"

            Item {
                id: osdContent
                width: 55
                height: 220
                x: 10
                anchors.verticalCenter: parent.verticalCenter

                property real slideX: osdVisible ? 0 : -100
                transform: Translate {
                    x: osdContent.slideX
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                opacity: osdVisible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: MatugenColors.md3.surface_container
                    opacity: 0.95

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0; verticalOffset: 0
                        radius: 9; samples: 17
                        color: MatugenColors.md3.shadow
                    }

                    Item {
                        anchors.fill: parent

                        Rectangle {
                            id: osdBarBg
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                top: parent.top
                                bottom: osdIcon.top
                                topMargin: 32
                                bottomMargin: 10
                            }
                            width: 10
                            radius: 5
                            color: ColorUtils.transparentize(MatugenColors.md3.on_surface_variant, 0.75)

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                radius: parent.radius
                                height: parent.height * displayVolume
                                color: displayColor

                                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on color  { ColorAnimation  { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                function updateValue(mouseY) {
                                    const v = Math.max(0.0, Math.min(1.0, 1.0 - mouseY / parent.height))
                                    if (osdMode === "speaker") {
                                        Audio.sink.volume = v
                                    } else if (osdMode === "mic") {
                                        if (Audio.source?.audio) Audio.source.audio.volume = v
                                    } else if (osdMode === "brightness") {
                                        const b = Math.round(v * 100)
                                        BrightnessOSDService.show(b)
                                        brightnessSetProc.command = ["hyprctl", "hyprsunset", "gamma", b.toString()]
                                        brightnessSetProc.running = true
                                    }
                                }
                                onPressed:         function(m) { updateValue(m.y) }
                                onPositionChanged: function(m) { if (pressed) updateValue(m.y) }
                            }
                        }

                        Text {
                            id: osdIcon
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                bottom: parent.bottom
                                bottomMargin: 10
                            }
                            font.family: "Material Symbols Rounded"
                            font.variableAxes: ({ "FILL": 1 })
                            renderType: Text.NativeRendering
                            font.pixelSize: 24
                            text:    shownIcon
                            color:   displayColor
                            opacity: iconOpacity
                            scale:   iconScale

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }
}
