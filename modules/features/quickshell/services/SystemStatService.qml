pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Public properties
    property real cpuUsage:    0   // 0–100
    property real cpuTemp:     0   // °C
    property real memPercent:  0   // 0–100
    property real memGb:       0   // used GB
    property real diskPercent: 0   // 0–100 (root fs)

    // Internal CPU state
    property var  prevCpuStats: null

    // Internal temperature state (mirrors noctalia approach)
    readonly property var supportedTempSensors: ["coretemp", "k10temp", "zenpower"]
    property string cpuTempSensorName: ""
    property string cpuTempHwmonPath:  ""
    property var    intelTempValues:   []
    property int    intelTempChecked:  0
    property int    intelTempMaxFiles: 20

    // ── Timer ──────────────────────────────────────────────────────────────
    Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: {
            cpuFile.reload()
            memFile.reload()
            diskProc.running = true
            root.updateCpuTemp()
        }
    }

    // ── File readers ────────────────────────────────────────────────────────
    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: root.parseCpu(text())
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: root.parseMem(text())
    }

    // ── Disk via df ─────────────────────────────────────────────────────────
    Process {
        id: diskProc
        command: ["df", "-P", "/"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n')
                if (lines.length >= 2) {
                    const parts = lines[1].trim().split(/\s+/)
                    if (parts.length >= 5)
                        root.diskPercent = parseInt(parts[4]) || 0
                }
            }
        }
    }

    // ── CPU temperature — step 1: probe hwmon for a known sensor name ───────
    FileView {
        id: hwmonNameReader
        property int probeIndex: 0
        printErrors: false

        function checkNext() {
            if (probeIndex >= 16) return   // give up after hwmon15
            hwmonNameReader.path = `/sys/class/hwmon/hwmon${probeIndex}/name`
            hwmonNameReader.reload()
        }

        onLoaded: {
            const name = text().trim()
            if (root.supportedTempSensors.includes(name)) {
                root.cpuTempSensorName = name
                root.cpuTempHwmonPath  = `/sys/class/hwmon/hwmon${probeIndex}`
            } else {
                probeIndex++
                Qt.callLater(checkNext)
            }
        }
        onLoadFailed: function(_) { probeIndex++; Qt.callLater(checkNext) }
    }

    // ── CPU temperature — step 2: read sensor value ──────────────────────────
    FileView {
        id: tempReader
        printErrors: false

        onLoaded: {
            const raw = text().trim()
            if (root.cpuTempSensorName === "coretemp") {
                root.intelTempValues.push(parseInt(raw) / 1000.0)
                Qt.callLater(root.checkNextIntelTemp)
            } else {
                root.cpuTemp = Math.round(parseInt(raw) / 1000.0)
            }
        }
        onLoadFailed: function(_) { Qt.callLater(root.checkNextIntelTemp) }
    }

    Component.onCompleted: hwmonNameReader.checkNext()

    // ── Parsers ─────────────────────────────────────────────────────────────
    function parseCpu(text) {
        if (!text) return
        const line = text.split('\n')[0]
        if (!line.startsWith('cpu ')) return
        const p = line.split(/\s+/)
        const s = {
            user:    parseInt(p[1]) || 0,
            nice:    parseInt(p[2]) || 0,
            system:  parseInt(p[3]) || 0,
            idle:    parseInt(p[4]) || 0,
            iowait:  parseInt(p[5]) || 0,
            irq:     parseInt(p[6]) || 0,
            softirq: parseInt(p[7]) || 0
        }
        const totalIdle = s.idle + s.iowait
        const total     = Object.values(s).reduce((a, v) => a + v, 0)
        if (root.prevCpuStats) {
            const pi = root.prevCpuStats.idle + root.prevCpuStats.iowait
            const pt = Object.values(root.prevCpuStats).reduce((a, v) => a + v, 0)
            const dt = total - pt, di = totalIdle - pi
            if (dt > 0) root.cpuUsage = (dt - di) / dt * 100
        }
        root.prevCpuStats = s
    }

    function parseMem(text) {
        if (!text) return
        let total = 0, avail = 0
        for (const line of text.split('\n')) {
            if (line.startsWith('MemTotal:'))
                total = parseInt(line.split(/\s+/)[1]) || 0
            else if (line.startsWith('MemAvailable:'))
                avail = parseInt(line.split(/\s+/)[1]) || 0
        }
        if (total > 0) {
            const used     = total - avail
            root.memGb      = parseFloat((used / 1048576).toFixed(1))
            root.memPercent = used / total * 100
        }
    }

    // ── Temperature helpers ─────────────────────────────────────────────────
    function updateCpuTemp() {
        if (!cpuTempHwmonPath) return
        if (cpuTempSensorName === "k10temp" || cpuTempSensorName === "zenpower") {
            tempReader.path = `${cpuTempHwmonPath}/temp1_input`
            tempReader.reload()
        } else if (cpuTempSensorName === "coretemp") {
            intelTempValues  = []
            intelTempChecked = 0
            checkNextIntelTemp()
        }
    }

    function checkNextIntelTemp() {
        if (intelTempChecked >= intelTempMaxFiles) {
            if (intelTempValues.length > 0) {
                const sum = intelTempValues.reduce((a, v) => a + v, 0)
                root.cpuTemp = Math.round(sum / intelTempValues.length)
            }
            return
        }
        intelTempChecked++
        tempReader.path = `${cpuTempHwmonPath}/temp${intelTempChecked}_input`
        tempReader.reload()
    }
}
