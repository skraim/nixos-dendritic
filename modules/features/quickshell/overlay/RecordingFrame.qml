import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.utils

Scope {
    // Border thickness
    readonly property int bw: 2

    Variants {
        model: Quickshell.screens

        delegate: Item {
            required property var modelData
            id: screenItem

            readonly property var mon: Hyprland.monitorFor(screenItem.modelData)

            // Local coords of the recording rect on this screen
            readonly property real lx: RecordingService.gx - (mon?.x ?? 0)
            readonly property real ly: RecordingService.gy - (mon?.y ?? 0)
            readonly property real lw: RecordingService.gw
            readonly property real lh: RecordingService.gh

            // Only show on the screen containing the selection's origin
            readonly property bool isTarget: {
                if (!RecordingService.active || !mon) return false
                return RecordingService.gx >= mon.x && RecordingService.gx < mon.x + mon.width
                    && RecordingService.gy >= mon.y && RecordingService.gy < mon.y + mon.height
            }

            // ── Top strip ────────────────────────────────────────────────
            PanelWindow {
                screen: screenItem.modelData
                color: MatugenColors.md3.error
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusiveZone: -1
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.focusable: false
                anchors.top: true; anchors.left: true
                margins.top:  screenItem.ly - bw
                margins.left: screenItem.lx - bw
                implicitWidth:  screenItem.isTarget ? screenItem.lw + 2 * bw : 0
                implicitHeight: screenItem.isTarget ? bw : 0
            }

            // ── Bottom strip ──────────────────────────────────────────────
            PanelWindow {
                screen: screenItem.modelData
                color: MatugenColors.md3.error
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusiveZone: -1
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.focusable: false
                anchors.top: true; anchors.left: true
                margins.top:  screenItem.ly + screenItem.lh
                margins.left: screenItem.lx - bw
                implicitWidth:  screenItem.isTarget ? screenItem.lw + 2 * bw : 0
                implicitHeight: screenItem.isTarget ? bw : 0
            }

            // ── Left strip ────────────────────────────────────────────────
            PanelWindow {
                screen: screenItem.modelData
                color: MatugenColors.md3.error
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusiveZone: -1
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.focusable: false
                anchors.top: true; anchors.left: true
                margins.top:  screenItem.ly
                margins.left: screenItem.lx - bw
                implicitWidth:  screenItem.isTarget ? bw : 0
                implicitHeight: screenItem.isTarget ? screenItem.lh : 0
            }

            // ── Right strip ───────────────────────────────────────────────
            PanelWindow {
                screen: screenItem.modelData
                color: MatugenColors.md3.error
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusiveZone: -1
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.focusable: false
                anchors.top: true; anchors.left: true
                margins.top:  screenItem.ly
                margins.left: screenItem.lx + screenItem.lw
                implicitWidth:  screenItem.isTarget ? bw : 0
                implicitHeight: screenItem.isTarget ? screenItem.lh : 0
            }
        }
    }
}
