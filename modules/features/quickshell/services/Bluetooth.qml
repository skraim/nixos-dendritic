pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell;
import Quickshell.Io;
import QtQuick;

Singleton {
    id: root

    property bool bluetoothEnabled: false
    property int bluetoothConnectedCount: 0

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            updateBluetoothEnabled.running = true
            interval = 5000
        }
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            updateBluetoothCount.running = true
            interval = 3000
        }
    }

    Process {
        id: updateBluetoothEnabled
        command: ["bluetoothctl", "show"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "Powered: yes")
                    root.bluetoothEnabled = true
            }
        }
    }

    Process {
        id: updateBluetoothCount
        command: ["bluetoothctl", "devices", "Connected"]
        running: true
        property int count: 0
        onRunningChanged: if (running) count = 0
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("Device "))
                    updateBluetoothCount.count++
            }
        }
        onExited: root.bluetoothConnectedCount = count
    }
}
