import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Qt5Compat.GraphicalEffects
import qs.services
import qs.utils

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusiveZone: -1
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            anchors.top: true; anchors.bottom: true
            anchors.left: true; anchors.right: true
            visible: win.visible
            onVisibleChanged: {
                if (visible && Hyprland.monitorFor(modelData)?.focused)
                    DashboardService.screen = modelData
                else if (!visible)
                    DashboardService.screen = null
            }
            MouseArea {
                anchors.fill: parent
                onClicked: DashboardService.dismiss()
            }
        }
    }

    PanelWindow {
        id: win

        property bool isOpen:     false
        property bool stableOpen: false
        property int  currentTab: 0
        property int  _lastTab:    0

        onIsOpenChanged: {
            if (isOpen) stableOpenTimer.start()
            else { stableOpenTimer.stop(); stableOpen = false }
        }

        Timer {
            id: stableOpenTimer
            interval: 220; repeat: false
            onTriggered: win.stableOpen = true
        }
        onCurrentTabChanged: {
            if (_lastTab === 1 && currentTab !== 1)
                notifTab.resetState()
            if (_lastTab === 2 && currentTab !== 2)
                overviewTab.resetState()
            _lastTab = currentTab
            DashboardService.currentTab = currentTab
            if (win.isOpen && currentTab === 2)
                WeatherService.refreshHourlySlots()
            win.btExpanded = false
            win.vpnExpanded = false
            controlsTab.outputDropdown.expanded = false
            controlsTab.inputDropdown.expanded  = false
        }
        readonly property var adapter: Bluetooth.defaultAdapter

        property var    cavaBars:           []
        property string selectedPlayerName: ""
        property bool   btExpanded:         false
        property bool   vpnExpanded:        false
        property string _pendingOpen:       ""

        function _anyOtherOpen(which) {
            if (which !== "bt"     && win.btExpanded)                        return true
            if (which !== "vpn"    && win.vpnExpanded)                       return true
            if (which !== "output" && controlsTab.outputDropdown.expanded)   return true
            if (which !== "input"  && controlsTab.inputDropdown.expanded)    return true
            return false
        }
        function _closeAllExcept(which) {
            if (which !== "bt")     win.btExpanded                       = false
            if (which !== "vpn")    win.vpnExpanded                      = false
            if (which !== "output") controlsTab.outputDropdown.expanded  = false
            if (which !== "input")  controlsTab.inputDropdown.expanded   = false
        }
        function _requestOpen(which) {
            if (_anyOtherOpen(which)) {
                _closeAllExcept(which)
                win._pendingOpen = which
                _pendingOpenTimer.restart()
            } else {
                _pendingOpenTimer.stop()
                win._pendingOpen = ""
            }
        }

        onBtExpandedChanged: {
            if (!win.btExpanded) return
            if (_anyOtherOpen("bt")) {
                win.btExpanded = false
                _requestOpen("bt")
            }
        }
        onVpnExpandedChanged: {
            if (!win.vpnExpanded) return
            if (_anyOtherOpen("vpn")) {
                win.vpnExpanded = false
                _requestOpen("vpn")
            }
        }

        Connections {
            target: controlsTab.outputDropdown
            function onExpandedChanged() {
                if (!controlsTab.outputDropdown.expanded) return
                if (win._anyOtherOpen("output")) {
                    controlsTab.outputDropdown.expanded = false
                    win._requestOpen("output")
                }
            }
        }
        Connections {
            target: controlsTab.inputDropdown
            function onExpandedChanged() {
                if (!controlsTab.inputDropdown.expanded) return
                if (win._anyOtherOpen("input")) {
                    controlsTab.inputDropdown.expanded = false
                    win._requestOpen("input")
                }
            }
        }

        Timer {
            id: _pendingOpenTimer
            interval: 240
            repeat: false
            onTriggered: {
                const p = win._pendingOpen
                win._pendingOpen = ""
                if      (p === "bt")     win.btExpanded                      = true
                else if (p === "vpn")    win.vpnExpanded                     = true
                else if (p === "output") controlsTab.outputDropdown.expanded = true
                else if (p === "input")  controlsTab.inputDropdown.expanded  = true
            }
        }
        property bool   tabHintMode:        false
        property bool   outputFocused:      false
        property bool   outputHintMode:    false
        property int    outputDeviceIdx:   -1
        property bool   inputFocused:      false
        property bool   inputHintMode:     false
        property int    inputDeviceIdx:    -1
        property bool   btFocused:         false
        property bool   btHintMode:        false
        property int    btFocusIdx:        -1
        property bool   vpnFocused:        false
        property int    vpnFocusIdx:       -1
        property bool   notifFocused:      false
        property int    notifFocusIdx:     -1
        property string notifSelectionSource: "keyboard"
        property bool   notifHintMode:     false
        property bool   playerDropdownOpen: false

        readonly property var connectedVpn: {
            const gw = Network.vpnGateway.toLowerCase()
            if (!gw) return null
            for (const v of Settings.vpns) if (gw.includes(v.partial_gw_name.toLowerCase())) return v
            return null
        }
        property real   mediaPosition:      0

        readonly property var activePlayer: {
            const ps = Mpris.players.values
            if (ps.length === 0) return null
            if (selectedPlayerName)
                for (const p of ps) if (p.identity === selectedPlayerName) return p
            for (const p of ps) if (p.isPlaying) return p
            return ps[0]
        }
        readonly property bool isPlaying: activePlayer?.isPlaying ?? false
        readonly property string activeArtUrl: mediaArtUrl(activePlayer)

        function metadataValue(player, key) {
            const md = player?.metadata;
            if (!md)
                return "";

            const value = md[key];
            if (value === undefined || value === null)
                return "";
            if (Array.isArray(value))
                return value.length > 0 ? String(value[0]) : "";
            return String(value);
        }

        function youtubeVideoIdFromUrl(url) {
            if (!url)
                return "";

            let decoded = String(url);
            try {
                decoded = decodeURIComponent(decoded);
            } catch (e) {}
            const patterns = [
                /[?&]v=([A-Za-z0-9_-]{11})/,
                /youtu\.be\/([A-Za-z0-9_-]{11})/,
                /youtube\.com\/(?:embed|shorts|live)\/([A-Za-z0-9_-]{11})/
            ];

            for (const pattern of patterns) {
                const match = decoded.match(pattern);
                if (match)
                    return match[1];
            }
            return "";
        }

        function mediaArtUrl(player) {
            const artUrl = player?.trackArtUrl || metadataValue(player, "mpris:artUrl");
            if (artUrl)
                return artUrl;

            const videoId = youtubeVideoIdFromUrl(metadataValue(player, "xesam:url") || metadataValue(player, "mpris:trackid"));
            return videoId ? "https://img.youtube.com/vi/" + videoId + "/hqdefault.jpg" : "";
        }

        function compareLabels(a, b) {
            const left = String(a ?? "").toLowerCase();
            const right = String(b ?? "").toLowerCase();
            if (left < right)
                return -1;
            if (left > right)
                return 1;
            return 0;
        }

        function sortedByLabel(items, labelFn) {
            const sorted = items.slice();
            sorted.sort((a, b) => compareLabels(labelFn(a), labelFn(b)));
            return sorted;
        }

        function bluetoothDeviceLabel(device) {
            return device?.name || "";
        }

        function vpnLabel(vpn) {
            return vpn?.short_name || vpn?.partial_gw_name || vpn?.toggler_path || "";
        }

        onActivePlayerChanged: mediaPosition = activePlayer?.position ?? 0

        readonly property var btAllDevices:       win.adapter?.devices.values ?? []
        readonly property var btConnectedDevices: sortedByLabel(btAllDevices.filter(d => d.connected), bluetoothDeviceLabel)
        readonly property int btHiddenCount:      btAllDevices.length - btConnectedDevices.length

        // Notification center state
        property var expandedNotifIds: []
        property var closingNotifIds: []

        function notificationClosing(notif) {
            const id = notificationId(notif)
            return id >= 0 && closingNotifIds.includes(id)
        }

        function requestDismissNotification(notif) {
            const id = notificationId(notif)
            if (id < 0 || closingNotifIds.includes(id))
                return
            removeNotificationBodyState(notif)
            closingNotifIds = [...closingNotifIds, id]
        }

        function requestDismissNotifications(notifs) {
            const nextIds = []
            for (const notif of notifs) {
                const id = notificationId(notif)
                if (id >= 0 && !closingNotifIds.includes(id)) {
                    removeNotificationBodyState(notif)
                    nextIds.push(id)
                }
            }
            if (nextIds.length > 0)
                closingNotifIds = [...closingNotifIds, ...nextIds]
        }

        function finishDismissNotification(id) {
            if (!closingNotifIds.includes(id))
                return
            closingNotifIds = closingNotifIds.filter(n => n !== id)
            NotificationsService.removeNotification(id)
        }

        // Weather expand state
        property bool weatherHourlyOpen: false
        property bool weatherDailyOpen:  false

        readonly property var notifItems: {
            NotificationsService.updateCounter  // reactive dependency
            const all = NotificationsService.allNotifications
            const urgent = []
            const normal = []
            function compareNewestFirst(a, b) {
                const aTime = a?.time instanceof Date ? a.time.getTime() : 0
                const bTime = b?.time instanceof Date ? b.time.getTime() : 0
                if (aTime !== bTime)
                    return bTime - aTime
                return notificationId(b) - notificationId(a)
            }
            for (const id in all) {
                const n = all[id]
                if (n.urgency === 2)
                    urgent.push(n)
                else
                    normal.push(n)
            }
            urgent.sort(compareNewestFirst)
            normal.sort(compareNewestFirst)
            return urgent.concat(normal)
        }
        onNotifItemsChanged: {
            if (notifItems.length === 0) {
                notifFocused = false
                notifFocusIdx = -1
                return
            }
            if (notifFocusIdx >= notifItems.length)
                notifFocusIdx = notifItems.length - 1
            if (notifFocusIdx < 0)
                return
        }

        function notificationId(notif) {
            return notif?.notification?.id ?? -1
        }

        function toggleNotificationBody(notif) {
            const id = notificationId(notif)
            if (id < 0)
                return
            expandedNotifIds = expandedNotifIds.includes(id)
                ? expandedNotifIds.filter(n => n !== id)
                : [...expandedNotifIds, id]
        }

        function removeNotificationBodyState(notif) {
            const id = notificationId(notif)
            if (id >= 0)
                expandedNotifIds = expandedNotifIds.filter(n => n !== id)
        }

        function clearHintModes() {
            tabHintMode = false
            outputHintMode = false
            inputHintMode = false
            btHintMode = false
            notifHintMode = false
        }

        visible: isOpen || closeTimer.running
        color: "transparent"
        exclusiveZone: -1

        property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(screen)
        property bool hasFullscreen: {
            if (!hyprMonitor) return false;
            const monId = hyprMonitor.id;
            const activeWsId = hyprMonitor.activeWorkspace?.id ?? -1;
            return [...HyprlandData.windowList.values].some(w => w.lastIpcObject?.fullscreen === 2 && w.monitor?.id === monId && w.workspace?.id === activeWsId);
        }

        property real panelLeftMargin: hasFullscreen ? -65 : 0
        Behavior on panelLeftMargin {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true; anchors.bottom: true
        anchors.left: true; anchors.right: true

        Connections {
            target: DashboardService
            function onVisibleChanged() {
                if (DashboardService.visible) {
                    win.currentTab = DashboardService.currentTab
                    win.isOpen = true
                    if (win.currentTab === 2)
                        WeatherService.refreshHourlySlots()
                    dashKeyCapture.forceActiveFocus()
                } else {
                    closeTimer.restart()
                    win.isOpen = false
                    win.btExpanded = false
                    win.vpnExpanded = false
                    notifTab.resetState()
                    overviewTab.resetState()
                    controlsTab.outputDropdown.expanded = false
                    controlsTab.inputDropdown.expanded  = false
                    win._pendingOpen = ""
                    _pendingOpenTimer.stop()
                    win.tabHintMode = false
                    win.outputFocused = false
                    win.outputHintMode = false
                    win.outputDeviceIdx = -1
                    win.inputFocused = false
                    win.inputHintMode = false
                    win.inputDeviceIdx = -1
                    win.btFocused = false
                    win.btHintMode = false
                    win.btFocusIdx = -1
                    win.vpnFocused = false
                    win.vpnFocusIdx = -1
                    win.notifFocused = false
                    win.notifFocusIdx = -1
                    win.notifHintMode = false
                }
            }
            function onCurrentTabChanged() {
                if (DashboardService.visible)
                    win.currentTab = DashboardService.currentTab
            }
        }

        Process {
            id: cavaProcess
            running: win.isOpen && win.currentTab === 3
            command: ["bash", "-c",
                "printf '[general]\\nbars=48\\nframerate=30\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=100\\nbar_delimiter=59\\nframe_delimiter=10\\n' > ~/.cache/quickshell/qs-cava.conf && exec cava -p ~/.cache/quickshell/qs-cava.conf"
            ]
            stdout: SplitParser {
                onRead: function(line) {
                    const l = line.trim()
                    if (!l) return
                    const parts = l.split(";").filter(v => v !== "")
                    if (parts.length > 0)
                        win.cavaBars = parts.map(v => parseInt(v) / 100.0)
                }
            }
        }

        Timer { id: closeTimer; interval: 200; repeat: false }

        Timer {
            interval: 1000; repeat: true; triggeredOnStart: true
            running: win.isOpen && win.currentTab === 3
            onTriggered: win.mediaPosition = win.activePlayer?.position ?? 0
        }

        MouseArea {
            anchors.fill: parent
            onClicked: DashboardService.dismiss()
        }

        // ── Keyboard navigation ───────────────────────────────────────────────
        Item {
            id: dashKeyCapture
            focus: true

            Keys.onEscapePressed: {
                if (win.outputDeviceIdx >= 0) {
                    win.outputDeviceIdx = -1; controlsTab.outputDropdown.expanded = false
                } else if (win.inputDeviceIdx >= 0) {
                    win.inputDeviceIdx = -1; controlsTab.inputDropdown.expanded = false
                } else if (win.notifHintMode || win.outputHintMode || win.btHintMode || win.inputHintMode || win.tabHintMode) {
                    win.clearHintModes()
                } else if (win.notifFocused) {
                    win.notifFocused = false; win.notifFocusIdx = -1
                } else if (win.btFocused) {
                    win.btFocused = false; win.btExpanded = false; win.btFocusIdx = -1
                } else if (win.vpnFocused) {
                    win.vpnFocused = false; win.vpnExpanded = false; win.vpnFocusIdx = -1
                } else if (win.outputFocused) {
                    win.outputFocused = false
                } else if (win.inputFocused) {
                    win.inputFocused = false
                } else {
                    DashboardService.dismiss()
                }
            }

            Keys.onPressed: function(event) {
                if (!win.isOpen) return
                const sc = Globals.scanCodes
                const ctrl = event.modifiers & Qt.ControlModifier

                // ── Close from any state ──────────────────────────────────────
                if (event.nativeScanCode === sc['Q']) { DashboardService.dismiss(); event.accepted = true; return }

                // ── Tab navigation — always reachable regardless of active section ──
                if (ctrl && (event.nativeScanCode === sc['C'] || event.nativeScanCode === sc['N']
                          || event.nativeScanCode === sc['O'] || event.nativeScanCode === sc['M'])) {
                    // Dismiss any active section
                    win.outputFocused = false;  win.outputHintMode = false; win.outputDeviceIdx = -1; controlsTab.outputDropdown.expanded = false
                    win.inputFocused  = false;  win.inputHintMode  = false; win.inputDeviceIdx  = -1; controlsTab.inputDropdown.expanded  = false
                    win.btFocused     = false;  win.btHintMode     = false; win.btFocusIdx      = -1; win.btExpanded = false
                    win.vpnFocused    = false;  win.vpnFocusIdx    = -1;    win.vpnExpanded     = false
                    win.notifFocused  = false;  win.notifFocusIdx  = -1;    win.notifHintMode = false
                    win.tabHintMode   = false
                    if      (event.nativeScanCode === sc['C']) win.currentTab = 0
                    else if (event.nativeScanCode === sc['N']) win.currentTab = 1
                    else if (event.nativeScanCode === sc['O']) win.currentTab = 2
                    else if (event.nativeScanCode === sc['M']) win.currentTab = 3
                    event.accepted = true; return
                }

                // ── VPN list navigation ───────────────────────────────────────
                if (win.vpnFocused) {
                    const vpnList = win.sortedByLabel(Settings.vpns.filter(v => v !== win.connectedVpn), win.vpnLabel)
                    if (event.nativeScanCode === sc['V']) {
                        win.vpnFocused = false; win.vpnExpanded = false; win.vpnFocusIdx = -1; event.accepted = true
                    } else if (event.key === Qt.Key_Up || event.nativeScanCode === sc['A']) {
                        win.vpnFocusIdx = Math.max(0, win.vpnFocusIdx - 1); event.accepted = true
                    } else if (event.key === Qt.Key_Down || event.nativeScanCode === sc['H']) {
                        win.vpnFocusIdx = Math.min(vpnList.length - 1, win.vpnFocusIdx + 1); event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        controlsTab.vpnListRepeater.itemAt(win.vpnFocusIdx)?.toggle()
                        event.accepted = true
                    }
                    return
                }

                // ── BT navigation ─────────────────────────────────────────────
                if (win.btFocused) {
                    const connCount = win.btConnectedDevices.length
                    const totalCount = connCount + (win.btExpanded ? controlsTab.btCombinedModel.count : 0)
                    if (event.nativeScanCode === sc['B']) {
                        win.btFocused = false; win.btExpanded = false; win.btFocusIdx = -1; win.btHintMode = false; event.accepted = true
                    } else if (event.key === Qt.Key_Up || event.nativeScanCode === sc['A']) {
                        if (win.btFocusIdx > 0) {
                            win.btFocusIdx--
                            const li = win.btFocusIdx - connCount
                            if (li >= 0) controlsTab.btDevList.scrollToIndex(li, false)
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down || event.nativeScanCode === sc['H']) {
                        if (win.btFocusIdx < totalCount - 1) {
                            win.btFocusIdx++
                            const li = win.btFocusIdx - connCount
                            if (li >= 0) controlsTab.btDevList.scrollToIndex(li, false)
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        let dev = null
                        if (win.btFocusIdx < connCount) {
                            dev = win.btConnectedDevices[win.btFocusIdx]
                        } else {
                            const li = win.btFocusIdx - connCount
                            if (li < controlsTab.btCombinedModel.count) dev = controlsTab.btCombinedModel.get(li).btDevice
                        }
                        if (dev && !win.btFocused) return
                        if (dev) { if (dev.connected) dev.disconnect(); else dev.connect() }
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['S']) {
                        if (win.adapter) win.adapter.discovering = !win.adapter.discovering
                        win.btHintMode = false; event.accepted = true
                    } else if (event.nativeScanCode === sc['J']) {
                        win.btHintMode = !win.btHintMode; event.accepted = true
                    }
                    return
                }

                // ── Output device list navigation ─────────────────────────────
                if (win.outputDeviceIdx >= 0) {
                    if (event.key === Qt.Key_Up || event.nativeScanCode === sc['A']) {
                        win.outputDeviceIdx = Math.max(0, win.outputDeviceIdx - 1); event.accepted = true
                    } else if (event.key === Qt.Key_Down || event.nativeScanCode === sc['H']) {
                        win.outputDeviceIdx = Math.min(controlsTab.outputDropdown.nodes.length - 1, win.outputDeviceIdx + 1); event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        const node = controlsTab.outputDropdown.nodes[win.outputDeviceIdx]
                        if (node) { controlsTab.outputDropdown.selected(node); controlsTab.outputDropdown.expanded = false }
                        win.outputDeviceIdx = -1; event.accepted = true
                    }
                    return
                }

                // ── Input device list navigation ──────────────────────────────
                if (win.inputDeviceIdx >= 0) {
                    if (event.key === Qt.Key_Up || event.nativeScanCode === sc['A']) {
                        win.inputDeviceIdx = Math.max(0, win.inputDeviceIdx - 1); event.accepted = true
                    } else if (event.key === Qt.Key_Down || event.nativeScanCode === sc['H']) {
                        win.inputDeviceIdx = Math.min(controlsTab.inputDropdown.nodes.length - 1, win.inputDeviceIdx + 1); event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        const node = controlsTab.inputDropdown.nodes[win.inputDeviceIdx]
                        if (node) { controlsTab.inputDropdown.selected(node); controlsTab.inputDropdown.expanded = false }
                        win.inputDeviceIdx = -1; event.accepted = true
                    }
                    return
                }

                // ── Output volume navigation ──────────────────────────────────
                if (win.outputFocused) {
                    if (event.nativeScanCode === sc['O']) {
                        win.outputFocused = false; win.outputHintMode = false; event.accepted = true
                    } else if (event.key === Qt.Key_Right || event.nativeScanCode === sc['E']) {
                        if (Audio.sink?.audio) Audio.sink.audio.volume = Math.min(1.0, Audio.sink.audio.volume + 0.05); event.accepted = true
                    } else if (event.key === Qt.Key_Left || event.nativeScanCode === sc['Y']) {
                        if (Audio.sink?.audio) Audio.sink.audio.volume = Math.max(0.0, Audio.sink.audio.volume - 0.05); event.accepted = true
                    } else if (event.nativeScanCode === sc['M'] && !ctrl) {
                        if (Audio.sink?.audio) Audio.sink.audio.muted = !Audio.sink.audio.muted
                        win.outputHintMode = false; event.accepted = true
                    } else if (event.nativeScanCode === sc['C']) {
                        controlsTab.outputDropdown.expanded = true; win.outputDeviceIdx = 0; win.outputHintMode = false; event.accepted = true
                    } else if (event.nativeScanCode === sc['J']) {
                        win.outputHintMode = !win.outputHintMode; event.accepted = true
                    }
                    return
                }

                // ── Input volume navigation ───────────────────────────────────
                if (win.inputFocused) {
                    if (event.nativeScanCode === sc['I']) {
                        win.inputFocused = false; win.inputHintMode = false; event.accepted = true
                    } else if (event.key === Qt.Key_Right || event.nativeScanCode === sc['E']) {
                        if (Audio.source?.audio) Audio.source.audio.volume = Math.min(1.0, Audio.source.audio.volume + 0.05); event.accepted = true
                    } else if (event.key === Qt.Key_Left || event.nativeScanCode === sc['Y']) {
                        if (Audio.source?.audio) Audio.source.audio.volume = Math.max(0.0, Audio.source.audio.volume - 0.05); event.accepted = true
                    } else if (event.nativeScanCode === sc['M'] && !ctrl) {
                        if (Audio.source?.audio) Audio.source.audio.muted = !Audio.source.audio.muted
                        win.inputHintMode = false; event.accepted = true
                    } else if (event.nativeScanCode === sc['C']) {
                        controlsTab.inputDropdown.expanded = true; win.inputDeviceIdx = 0; win.inputHintMode = false; event.accepted = true
                    } else if (event.nativeScanCode === sc['J']) {
                        win.inputHintMode = !win.inputHintMode; event.accepted = true
                    }
                    return
                }

                // ── Tab 1: Notifications ─────────────────────────────────────
                if (win.currentTab === 1) {
                    function focusNotification(idx) {
                        const len = win.notifItems.length
                        if (len <= 0) {
                            win.notifFocused = false
                            win.notifFocusIdx = -1
                            return
                        }
                        const clampedIdx = Math.max(0, Math.min(len - 1, idx))
                        win.notifSelectionSource = "keyboard"
                        win.notifFocused = true
                        win.notifFocusIdx = clampedIdx
                        win.clearHintModes()
                    }

                    if (event.nativeScanCode === sc['J']) {
                        const on = !win.notifHintMode
                        if (on) {
                            win.notifHintMode = true; win.tabHintMode = true
                        } else {
                            win.clearHintModes()
                        }
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['D']) {
                        NotificationsService.toggleDnd()
                        win.clearHintModes()
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['C'] && !ctrl) {
                        win.requestDismissNotifications(Object.values(NotificationsService.allNotifications))
                        win.notifFocused = false; win.notifFocusIdx = -1; win.clearHintModes()
                        event.accepted = true; return
                    }
                    if (event.key === Qt.Key_Down || event.nativeScanCode === sc['H']) {
                        focusNotification((!win.notifFocused || win.notifFocusIdx < 0) ? 0 : win.notifFocusIdx + 1)
                        event.accepted = true; return
                    }
                    if (event.key === Qt.Key_Up || event.nativeScanCode === sc['A']) {
                        focusNotification((!win.notifFocused || win.notifFocusIdx < 0) ? 0 : win.notifFocusIdx - 1)
                        event.accepted = true; return
                    }
                    if (win.notifFocused && win.notifFocusIdx >= 0) {
                        const notif = win.notifItems[win.notifFocusIdx]
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            win.toggleNotificationBody(notif)
                            win.clearHintModes()
                            event.accepted = true; return
                        }
                        if (event.nativeScanCode === sc['X']) {
                            if (notif)
                                win.requestDismissNotification(notif)
                            win.clearHintModes()
                            event.accepted = true; return
                        }
                    }
                }

                // ── Tab 2: Overview ──────────────────────────────────────────
                if (win.currentTab === 2) {
                    if (event.key === Qt.Key_Down || event.nativeScanCode === sc['H']) {
                        if (!win.weatherHourlyOpen) win.weatherHourlyOpen = true
                        else if (!win.weatherDailyOpen) win.weatherDailyOpen = true
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.key === Qt.Key_Up || event.nativeScanCode === sc['A']) {
                        if (win.weatherDailyOpen) win.weatherDailyOpen = false
                        else if (win.weatherHourlyOpen) win.weatherHourlyOpen = false
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['E']) {
                        if (win.weatherHourlyOpen)
                            overviewTab.hourlyFlickable.scrollBy(74)
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['Y']) {
                        if (win.weatherHourlyOpen)
                            overviewTab.hourlyFlickable.scrollBy(-74)
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['N'] && !ctrl) {
                        overviewTab.calendarWidget.monthOffset++
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['P'] && !ctrl) {
                        overviewTab.calendarWidget.monthOffset--
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                }

                // ── Tab 3: Media ─────────────────────────────────────────────
                if (win.currentTab === 3) {
                    if (event.key === Qt.Key_Space) {
                        win.activePlayer?.togglePlaying()
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['N'] && !ctrl) {
                        win.activePlayer?.next(); win.mediaPosition = 0
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['P'] && !ctrl) {
                        win.activePlayer?.previous(); win.mediaPosition = 0
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['E'] || event.key === Qt.Key_Right) {
                        if (win.activePlayer) {
                            const p = Math.min(win.activePlayer.length ?? 0, win.mediaPosition + 15)
                            win.activePlayer.position = p; win.mediaPosition = p
                        }
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.nativeScanCode === sc['Y'] || event.key === Qt.Key_Left) {
                        if (win.activePlayer) {
                            const p = Math.max(0, win.mediaPosition - 15)
                            win.activePlayer.position = p; win.mediaPosition = p
                        }
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                    if (event.key === Qt.Key_Tab) {
                        const ps = Mpris.players.values
                        if (ps.length > 1) {
                            const idx = ps.findIndex(p => p === win.activePlayer)
                            win.selectedPlayerName = ps[(idx + 1) % ps.length].identity
                        }
                        win.tabHintMode = false
                        event.accepted = true; return
                    }
                }

                // ── Global shortcuts ──────────────────────────────────────────
                if (event.nativeScanCode === sc['J']) { win.tabHintMode = !win.tabHintMode; event.accepted = true }
                else if (event.nativeScanCode === sc['W'] && win.currentTab === 0) {
                    Network.setWifiEnabled(!Network.wifiEnabled); win.tabHintMode = false; event.accepted = true
                } else if (event.nativeScanCode === sc['O'] && win.currentTab === 0) {
                    win.outputFocused = !win.outputFocused; win.outputHintMode = false; win.inputFocused = false; win.inputHintMode = false; win.tabHintMode = false; event.accepted = true
                } else if (event.nativeScanCode === sc['I'] && win.currentTab === 0) {
                    win.inputFocused = !win.inputFocused; win.inputHintMode = false; win.outputFocused = false; win.outputHintMode = false; win.tabHintMode = false; event.accepted = true
                } else if (event.nativeScanCode === sc['B'] && win.currentTab === 0) {
                    win.btFocused = true; win.btExpanded = true; win.btFocusIdx = 0
                    win.outputFocused = false; win.inputFocused = false; win.tabHintMode = false; event.accepted = true
                } else if (event.nativeScanCode === sc['V'] && win.currentTab === 0) {
                    win.vpnFocused = true; win.vpnExpanded = true; win.vpnFocusIdx = 0
                    win.outputFocused = false; win.inputFocused = false; win.btFocused = false; win.tabHintMode = false; event.accepted = true
                } else if (event.nativeScanCode === sc['D'] && win.currentTab === 0 && Network.vpnConnected) {
                    Quickshell.execDetached(["bash", "-c", Settings.disconnectVpnsPath]); event.accepted = true
                } else if (event.nativeScanCode === sc['E'] && win.currentTab === 0 && PowerProfiles) {
                    PowerProfiles.profile = PowerProfile.PowerSaver; win.tabHintMode = false; event.accepted = true
                } else if (event.nativeScanCode === sc['N'] && win.currentTab === 0 && PowerProfiles) {
                    PowerProfiles.profile = PowerProfile.Balanced; win.tabHintMode = false; event.accepted = true
                } else if (event.nativeScanCode === sc['P'] && win.currentTab === 0 && PowerProfiles) {
                    PowerProfiles.profile = PowerProfile.Performance; win.tabHintMode = false; event.accepted = true
                }
            }
        }

        // ── Panel shadow + outer corners (unified, rendered below the panel) ──
        Item {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.leftMargin: win.panelLeftMargin
            width:  553 + Globals.componentRadius
            height: panel.height + Globals.componentRadius

            opacity: panel.opacity
            scale:   panel.scale
            transformOrigin: Item.BottomLeft

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: -4
                radius: 24; samples: 40; color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.33)
            }

            // Mirrors the panel rectangle so the shadow covers the full panel shape
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                width:  553
                height: panel.height
                color: MatugenColors.md3.surface_container_high
                topLeftRadius:    Globals.componentRadius
                topRightRadius:   Globals.componentRadius
                bottomLeftRadius: 0
                bottomRightRadius: Globals.componentRadius
            }

            // Top-left outer corner
            Shape {
                anchors.top:  parent.top
                anchors.left: parent.left
                anchors.leftMargin: -win.panelLeftMargin
                width:  Globals.componentRadius
                height: Globals.componentRadius
                preferredRendererType: Shape.CurveRenderer
                enabled: false

                ShapePath {
                    property color bg: Qt.color(MatugenColors.md3.surface_container_high)
                    strokeWidth: -1
                    fillColor: Qt.rgba(bg.r, bg.g, bg.b, 1)

                    PathArc {
                        relativeX: Globals.componentRadius; relativeY: Globals.componentRadius
                        radiusX: Globals.componentRadius;   radiusY: Globals.componentRadius
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { relativeX: -Globals.componentRadius; relativeY: 0 }
                }
            }

            // Bottom-right outer corner
            Shape {
                anchors.right:  parent.right
                anchors.bottom: parent.bottom
                width:  Globals.componentRadius
                height: Globals.componentRadius
                preferredRendererType: Shape.CurveRenderer
                enabled: false

                ShapePath {
                    property color bg: Qt.color(MatugenColors.md3.surface_container_high)
                    strokeWidth: -1
                    fillColor: Qt.rgba(bg.r, bg.g, bg.b, 1)

                    PathLine { relativeX: 0;                       relativeY: Globals.componentRadius }
                    PathLine { relativeX: Globals.componentRadius; relativeY: 0 }
                    PathArc {
                        relativeX: -Globals.componentRadius; relativeY: -Globals.componentRadius
                        radiusX: Globals.componentRadius;    radiusY: Globals.componentRadius
                        direction: PathArc.Clockwise
                    }
                }
            }
        }

        // ── Panel ────────────────────────────────────────────────────────────
        Item {
            id: panel
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.bottomMargin: 0
            anchors.leftMargin:   win.panelLeftMargin

            width: 553
            transformOrigin: Item.BottomLeft

            // Height adapts to active tab's content
            height: {
                const overhead = 14 + 52 + 1 + 24  // tabbar topMargin + tabbar + separator + flickable margins
                if (win.currentTab === 1) return win.height * .5
                const maxH = win.height * 0.82
                const contentH = win.currentTab === 0 ? controlsTab.contentImplicitHeight
                    : win.currentTab === 2          ? overviewTab.contentImplicitHeight
                    : mediaTab.contentImplicitHeight
                return Math.min(contentH + overhead, maxH)
            }

            opacity: 0.0
            transform: Translate { id: panelTranslate; x: -24; y: 24 }
            Behavior on height { enabled: win.stableOpen; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            states: [
                State {
                    name: "open"
                    when: win.isOpen
                    PropertyChanges { panel.opacity: 1.0 }
                    PropertyChanges { panelTranslate.x: 0; panelTranslate.y: 0 }
                },
                State {
                    name: "closed"
                    when: !win.isOpen
                    PropertyChanges { panel.opacity: 0.0 }
                    PropertyChanges { panelTranslate.x: -24; panelTranslate.y: 24 }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { target: panel;         property: "opacity"; duration: 180; easing.type: Easing.OutCubic }
                        NumberAnimation { target: panelTranslate; properties: "x,y";  duration: 220; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    SequentialAnimation {
                        NumberAnimation { target: panel; property: "opacity"; duration: 180; easing.type: Easing.OutCubic }
                        PropertyAction  { target: panelTranslate; properties: "x,y" }
                    }
                }
            ]

            MouseArea { anchors.fill: parent; onClicked: {} }

            Rectangle {
                anchors.fill: parent
                color: MatugenColors.md3.surface_container_high
                topRightRadius: Globals.componentRadius
                clip: true

                Rectangle {
                    anchors.fill: parent
                    // topLeftRadius: Globals.componentRadius
                    // topRightRadius: Globals.componentRadius
                    // bottomLeftRadius: 0
                    bottomRightRadius: Globals.componentRadius
                    color: "transparent"
                    // border.width: 1
                    // border.color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.9)
                }

                // ── Tab bar ──────────────────────────────────────────────────
                RowLayout {
                    id: tabBar
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    anchors.leftMargin: 73
                    anchors.topMargin: 14
                    anchors.rightMargin: 14
                    height: 52
                    spacing: 0

                    Repeater {
                        model: [
                            {
                                icon: "tune",
                                label: Localization.t("dashboard.tabs.controls", "Controls")
                            },
                            {
                                icon: "\ue7f4",
                                label: Localization.t("dashboard.tabs.notifications", "Notifications")
                            },
                            {
                                icon: "today",
                                label: Localization.t("dashboard.tabs.overview", "Overview")
                            },
                            {
                                icon: "library_music",
                                label: Localization.t("dashboard.tabs.media", "Media")
                            }
                        ]
                        delegate: Item {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            height: 52
                            readonly property bool active: win.currentTab === index

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 32; height: 2; radius: 1
                                color: MatugenColors.md3.primary
                                opacity: active ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: tabIcon.implicitWidth
                                    implicitHeight: tabIcon.implicitHeight

                                    Text {
                                        id: tabIcon
                                        anchors.centerIn: parent
                                        font.family: "Material Symbols Rounded"; font.pixelSize: 22
                                        font.variableAxes: ({ "FILL": 1 })
                                        renderType: Text.NativeRendering
                                        color: active ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                                        opacity: active ? 1.0 : (tabMouse.containsMouse ? 0.7 : 0.38)
                                        text: modelData.icon
                                        Behavior on color   { ColorAnimation  { duration: 160 } }
                                        Behavior on opacity { NumberAnimation { duration: 160 } }
                                    }

                                    // Key hint badge — centered on the icon's bottom-right corner
                                    Rectangle {
                                        anchors.horizontalCenter: tabIcon.right
                                        anchors.verticalCenter: tabIcon.bottom
                                        anchors.verticalCenterOffset: -6
                                        opacity: win.tabHintMode ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                        width: 24; height: 16; radius: 3
                                        color: MatugenColors.md3.primary
                                        z: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: (["^C", "^N", "^O", "^M"])[index]
                                            font.pixelSize: 9; font.bold: true
                                            color: MatugenColors.md3.on_primary
                                        }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                     font.pixelSize: 11; font.letterSpacing: 0.8
                                    color: active ? MatugenColors.md3.primary : MatugenColors.md3.on_surface
                                    opacity: active ? 1.0 : (tabMouse.containsMouse ? 0.7 : 0.38)
                                    text: modelData.label
                                    Behavior on color   { ColorAnimation  { duration: 160 } }
                                    Behavior on opacity { NumberAnimation { duration: 160 } }
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { win.tabHintMode = false; win.currentTab = index }
                            }
                        }
                    }
                }

                // Tab bar separator
                Rectangle {
                    id: tabSep
                    anchors { left: parent.left; right: parent.right; top: tabBar.bottom }
                    anchors.leftMargin: 73
                    anchors.rightMargin: 14
                    height: 1
                    color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.92)
                }

                // ── Content area (shared panel, different per tab) ───────────
                Item {
                    anchors {
                        left: parent.left; right: parent.right
                        top: tabSep.bottom; bottom: parent.bottom
                    }
                    anchors.leftMargin: 73
                    anchors.rightMargin: 14
                    clip: true

                    DashboardControlsTab {
                        id: controlsTab
                        anchors.fill: parent
                        win: win
                        visible: win.currentTab === 0
                    }
                    DashboardNotificationsTab {
                        id: notifTab
                        anchors.fill: parent
                        win: win
                        visible: win.currentTab === 1
                    }
                    DashboardOverviewTab {
                        id: overviewTab
                        anchors.fill: parent
                        win: win
                        visible: win.currentTab === 2
                    }
                    DashboardMediaTab {
                        id: mediaTab
                        anchors.fill: parent
                        win: win
                        visible: win.currentTab === 3
                    }
                }
            }
        }

    }

}
