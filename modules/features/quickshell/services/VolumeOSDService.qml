pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // OSD visibility state
    property bool visible: false
    property real currentVolume: 0.0
    property bool isMuted: false

    // Display timeout
    property int displayDuration: 2000  // ms

    Timer {
        id: hideTimer
        interval: root.displayDuration
        repeat: false
        onTriggered: root.visible = false
    }

    // Show the OSD with current volume
    function show(volume: real, muted: bool) {
        root.currentVolume = volume
        root.isMuted = muted
        root.visible = true
        hideTimer.restart()
    }

    // Hide the OSD
    function hide() {
        root.visible = false
        hideTimer.stop()
    }

    // Watch for volume changes
    Connections {
        target: Audio.sink?.audio

        function onVolumeChanged() {
            if (Audio.sink?.audio) {
                root.show(Audio.sink.audio.volume, Audio.sink.audio.muted)
            }
        }

        function onMutedChanged() {
            if (Audio.sink?.audio) {
                root.show(Audio.sink.audio.volume, Audio.sink.audio.muted)
            }
        }
    }
}
