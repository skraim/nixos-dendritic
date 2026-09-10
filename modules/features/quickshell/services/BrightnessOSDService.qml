pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real currentBrightness: 0.0
    signal showRequested()

    // Show the OSD with current brightness
    function show(brightness: real) {
        root.currentBrightness = brightness
        root.showRequested()
    }

    Process {
        id: brightnessQuery
        command: ["hyprctl", "hyprsunset", "gamma"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const brightness = parseFloat(this.text.trim())
                if (!isNaN(brightness)) {
                    root.show(brightness)
                }
            }
        }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void {
            brightnessQuery.running = true
        }
    }
}
