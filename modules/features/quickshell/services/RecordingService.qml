pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property bool   active: false
    property real   gx: 0
    property real   gy: 0
    property real   gw: 0
    property real   gh: 0
    property string lastAudioArgs: ""

    readonly property string _geomFile: "/tmp/qs-rec-geom"

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function shellDoubleQuotedPrefix(value) {
        return String(value).replace(/(["\\$`])/g, "\\$1")
    }

    function record(audioArgs) {
        root.lastAudioArgs = audioArgs
        const appName = shellQuote(Localization.t("notifications.recording.appName", "Recording"))
        const cancelledTitle = shellQuote(Localization.t("notifications.recording.cancelled.title", "Recording cancelled"))
        const multiMonitorBody = shellQuote(Localization.t("notifications.shared.selectionSpansMonitors", "Selection spans multiple monitors."))
        const savedTitle = shellQuote(Localization.t("notifications.recording.saved.title", "Recording saved"))
        const savedBodyPrefix = shellDoubleQuotedPrefix(Localization.t("notifications.shared.pathCopiedToClipboard", "Path copied to clipboard:"))
        // Remove stale geom file, then launch the whole pipeline detached (same
        // mechanism as screenshots — no pipes, so slurp can grab the pointer).
        const cmd = `rm -f ${root._geomFile}; `
                  + `geom=$(slurp ${Globals.slurpArgs}) || exit 1; `
                  + `read X Y W H <<<"$(echo "$geom" | sed 's/[,x]/ /g')"; `
                  + `if ! hyprctl monitors -j | jq -e --argjson x $X --argjson y $Y --argjson w $W --argjson h $H `
                  +     `'any(.[]; (.x <= $x) and (.y <= $y) and ((.x + (.width/.scale)) >= ($x+$w)) and ((.y + (.height/.scale)) >= ($y+$h)))' >/dev/null; then `
                  +     `notify-send -a ${appName} ${cancelledTitle} ${multiMonitorBody}; exit 1; `
                  + `fi; `
                  + `echo "$geom" > ${root._geomFile}; `
                  + `out="$HOME/Videos/Recordings/$(date +%F_%H-%M-%S)-rec.mp4"; `
                  + `wl-screenrec --geometry "$geom" ${audioArgs} `
                  + `-f "$out" && printf '%s' "$out" | wl-copy && notify-send -a ${appName} ${savedTitle} "${savedBodyPrefix} $out"`
        Quickshell.execDetached(["setsid", "bash", "-c", cmd])
        geomPoller.attempts = 0
        geomPoller.running = true
    }

    function stop() {
        stopProc.running = true
        root.active = false
    }

    // ── Poll for geom file after slurp selects a region ──────────────────
    Timer {
        id: geomPoller
        interval: 100
        repeat: true
        running: false
        property int attempts: 0

        onTriggered: {
            attempts++
            if (attempts > 60) {   // 6 s timeout — user cancelled slurp
                running = false
                return
            }
            geomReader.running = true
        }
    }

    Process {
        id: geomReader
        command: ["cat", root._geomFile]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const g = data.trim()
                if (!g) return
                const m = g.match(/^(\d+),(\d+)\s+(\d+)x(\d+)$/)
                if (!m) return
                root.gx = parseInt(m[1]); root.gy = parseInt(m[2])
                root.gw = parseInt(m[3]); root.gh = parseInt(m[4])
                root.active = true
                geomPoller.running = false
                const audioKey = root.lastAudioArgs.length > 0 ? "audio" : "no-audio"
                UsageTracker.record("screenrec:" + audioKey)
            }
        }
    }

    // ── Stop ─────────────────────────────────────────────────────────────
    Process {
        id: stopProc
        command: ["pkill", "-x", "wl-screenrec"]
        running: false
    }

    // ── Poll for recording end ────────────────────────────────────────────
    Process {
        id: checkProc
        command: ["pgrep", "-x", "wl-screenrec"]
        running: false
        onExited: (code) => {
            if (root.active && code !== 0) {
                root.active = false
            }
        }
    }

    Timer {
        interval: 1000; repeat: true; running: root.active
        onTriggered: checkProc.running = true
    }
}
