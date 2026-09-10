pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifi: true
    property bool wifiEnabled: true
    property bool ethernet: false
    property int updateIntervalGeneral: 1000
    property int updateIntervalVpn: 3000
    property string networkName: ""
    property string wifiSsid: ""
    property string ethernetName: ""
    property int networkStrength: 0
    property string vpnGateway: ""
    readonly property bool vpnConnected: vpnGateway.length > 0
    property string materialSymbol: ethernet ? "lan" :
        Network.wifi ? (
        Network.networkStrength > 80 ? "signal_wifi_4_bar" :
        Network.networkStrength > 60 ? "network_wifi_3_bar" :
        Network.networkStrength > 40 ? "network_wifi_2_bar" :
        Network.networkStrength > 20 ? "network_wifi_1_bar" :
        "signal_wifi_0_bar"
    ) : "signal_wifi_off"

    function updateGeneral() {
        updateWifiRadio.running = true;
        updateConnectionType.startCheck();
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
        updateWifiSsid.running = true;
        updateEthernetName.running = true;
    }

    function setWifiEnabled(enabled) {
        wifiEnabled = enabled;
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "on" : "off"]);
        wifiToggleRefresh.restart();
    }

    function updateVpn() {
        checkVpnGateway.startCheck()
    }

    Timer {
        id: wifiToggleRefresh
        interval: 700
        repeat: false
        onTriggered: root.updateGeneral()
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            root.updateGeneral();
            interval = root.updateIntervalGeneral;
        }
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            root.updateVpn();
            interval = root.updateIntervalVpn;
        }
    }

    Process {
        id: updateConnectionType
        property string buffer
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        running: true
        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            let hasEthernet = false;
            let hasWifi = false;
            lines.forEach(line => {
                if (line.includes("ethernet"))
                    hasEthernet = true;
                else if (line.includes("wireless"))
                    hasWifi = true;
            });
            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
        }
    }

    Process {
        id: updateWifiRadio
        property string buffer: ""
        command: ["nmcli", "radio", "wifi"]
        running: true
        onRunningChanged: if (running) buffer = ""
        stdout: SplitParser {
            onRead: data => {
                updateWifiRadio.buffer += data;
            }
        }
        onExited: {
            root.wifiEnabled = updateWifiRadio.buffer.trim() === "enabled";
        }
    }

    Process {
        id: updateNetworkName
        property bool receivedName: false
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
        running: true
        onRunningChanged: if (running) receivedName = false
        stdout: SplitParser {
            onRead: data => {
                if (!updateNetworkName.receivedName) {
                    root.networkName = data;
                    updateNetworkName.receivedName = true;
                }
            }
        }
    }

    Process {
        id: updateNetworkStrength
        property string buffer: ""
        running: true
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1 == \"*\" {print $2; exit}'"]
        onRunningChanged: if (running) buffer = ""
        stdout: SplitParser {
            onRead: data => {
                updateNetworkStrength.buffer += data;
            }
        }
        onExited: {
            const strength = parseInt(updateNetworkStrength.buffer.trim());
            root.networkStrength = isNaN(strength) ? 0 : strength;
        }
    }

    Process {
        id: updateEthernetName
        running: true
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        property bool receivedName: false
        onRunningChanged: if (running) receivedName = false
        stdout: SplitParser {
            onRead: data => {
                const separator = data.lastIndexOf(":");
                if (!updateEthernetName.receivedName && separator >= 0 && data.slice(separator + 1).includes("ethernet")) {
                    root.ethernetName = data.slice(0, separator);
                    updateEthernetName.receivedName = true;
                }
            }
        }
    }

    Process {
        id: updateWifiSsid
        running: true
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "device", "wifi"]
        property bool receivedSsid: false
        onRunningChanged: if (running) receivedSsid = false
        stdout: SplitParser {
            onRead: data => {
                if (!updateWifiSsid.receivedSsid && data.startsWith("yes:")) {
                    root.wifiSsid = data.slice(4);
                    updateWifiSsid.receivedSsid = true;
                }
            }
        }
    }

    Process {
        id: checkVpnGateway
        running: true
        command: ["sh", "-c", `${Quickshell.shellDir}/scripts/vpn-gateway.sh 2>/dev/null`]
        property string buffer: ""
        property string pendingGateway: ""
        function startCheck() { buffer = ""; checkVpnGateway.running = true }
        stdout: SplitParser {
            onRead: data => { checkVpnGateway.buffer += data }
        }
        onExited: {
            const result = checkVpnGateway.buffer.trim()
            if (result.length > 0) {
                root.vpnGateway = result
                pendingGateway = ""
            } else if (result === pendingGateway) {
                root.vpnGateway = result
                pendingGateway = ""
            } else {
                pendingGateway = result
            }
        }
    }
}
