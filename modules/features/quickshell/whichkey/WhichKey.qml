import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Qt5Compat.GraphicalEffects
import qs.services
import qs.utils

Scope {
    PanelWindow {
        id: win

        property bool isOpen: false
        // true while navigating a tray menu — WhichKey stays focused, popup hidden
        property bool trayNavMode: false

        readonly property var groupDefs: ({
            "window": {
                title: Localization.t("whichKey.groups.window", "Window"),
                icon: "blur_on",
                bindings: [
                    { key: "C", label: Localization.t("whichKey.bindings.window.close", "Close window") },
                    { key: "K", label: Localization.t("whichKey.bindings.window.kill", "Kill window") }
                ]
            },
            "picker": {
                title: Localization.t("whichKey.groups.pickers", "Pickers"),
                icon: "apps",
                bindings: [
                    { key: "B", label: Localization.t("whichKey.bindings.pickers.bluetooth", "Bluetooth") },
                    { key: "W", label: Localization.t("whichKey.bindings.pickers.wallpaper", "Wallpaper") },
                    { key: "P", label: Localization.t("whichKey.bindings.pickers.passmenu", "Passmenu") },
                    { key: "M", label: Localization.t("whichKey.bindings.pickers.virtualMachine", "Virtual Machine") },
                    { key: "V", label: Localization.t("whichKey.bindings.pickers.vpn", "VPN") },
                    { key: "O", label: Localization.t("whichKey.bindings.pickers.audioOutput", "Audio Output") },
                    { key: "U", label: Localization.t("whichKey.bindings.pickers.unmountDevice", "Unmount device") }
                ]
            },
            "browser": {
                title: Localization.t("whichKey.groups.browser", "Browser"),
                icon: "\ue051",
                bindings: [
                    { key: "L", label: Localization.t("whichKey.bindings.browser.librewolf", "Librewolf") },
                    { key: "D", label: Localization.t("whichKey.bindings.browser.chromiumDl", "Chromium (DL)") },
                    { key: "G", label: Localization.t("whichKey.bindings.browser.chromiumGeneral", "Chromium (General)") },
                    { key: "C", label: Localization.t("whichKey.bindings.browser.chromium", "Chromium") }
                ]
            },
            "bar": {
                title: Localization.t("whichKey.groups.bar", "Bar"),
                icon: "apps"
            },
            "screen": {
                title: Localization.t("whichKey.groups.screen", "Screen"),
                icon: "\ue3b0",
                bindings: [
                    { key: "C", label: Localization.t("whichKey.bindings.screen.screenshotClipboard", "Screenshot -> clipboard") },
                    { key: "A", label: Localization.t("whichKey.bindings.screen.screenshotAnnotate", "Screenshot -> annotate") },
                    { key: "S", label: Localization.t("whichKey.bindings.screen.screenshotSave", "Screenshot -> save") },
                    { key: "R", label: Localization.t("whichKey.bindings.screen.recordNoMic", "Record (no mic)") },
                    { key: "M", label: Localization.t("whichKey.bindings.screen.recordMic", "Record + mic") },
                    { key: "D", label: Localization.t("whichKey.bindings.screen.recordSystemAudio", "Record + system audio") },
                    { key: "X", label: Localization.t("whichKey.bindings.screen.stopRecording", "Stop recording") }
                ]
            }
        })

        readonly property var activeGroup: {
            const grp = groupDefs[WhichKeyService.group]
            if (!grp) return null
            if (WhichKeyService.group === "bar") {
                const bindings = []
                bindings.push({ keys: ["1", "9"], label: Localization.t("whichKey.bindings.bar.systemTray", "System tray") })
                bindings.push({ key: "N", label: Localization.t("whichKey.bindings.bar.notifications", "Notifications") })
                bindings.push({ key: "C", label: Localization.t("whichKey.bindings.bar.controls", "Controls") })
                bindings.push({ key: "O", label: Localization.t("whichKey.bindings.bar.overview", "Overview") })
                bindings.push({ key: "M", label: Localization.t("whichKey.bindings.bar.media", "Media") })
                return { title: grp.title, icon: grp.icon, bindings }
            }
            return grp
        }

        visible: isOpen || closeTimer.running
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen
            ? (trayNavMode ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive)
            : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        // Frozen snapshot of activeGroup held for the duration of the close animation,
        // preventing the popup from collapsing to a tiny rectangle while fading out.
        property var frozenGroup: null

        SequentialAnimation {
            id: groupTransition
            NumberAnimation { target: col; property: "opacity"; to: 0;  duration: 80;  easing.type: Easing.InCubic }
            ScriptAction    { script: win.frozenGroup = win.activeGroup }
            NumberAnimation { target: col; property: "opacity"; to: 1;  duration: 100; easing.type: Easing.OutCubic }
        }

        Connections {
            target: WhichKeyService
            function onVisibleChanged() {
                if (WhichKeyService.visible) {
                    groupTransition.stop()
                    col.opacity = 1
                    popup.behaviorEnabled = false
                    win.frozenGroup = win.activeGroup
                    win.isOpen = true
                    keyCapture.forceActiveFocus()
                    enableBehaviorTimer.restart()
                } else {
                    popup.behaviorEnabled = false
                    win.trayNavMode = false
                    closeTimer.restart()
                    win.isOpen = false
                }
            }
            function onGroupChanged() {
                if (win.isOpen) groupTransition.restart()
            }
        }

        // When TrayMenuPopup closes on its own (e.g. mouse click on background),
        // exit tray-nav mode and dismiss WhichKey.
        Connections {
            target: BarNavigationService
            function onTrayMenuClosed() {
                win.trayNavMode = false
                WhichKeyService.dismiss()
            }
        }

        function runCommand(cmd) {
            Quickshell.execDetached(["setsid", "bash", "-c", cmd])
            WhichKeyService.dismiss()
        }

        function shellQuote(value) {
            return "'" + String(value).replace(/'/g, "'\\''") + "'"
        }

        function shellDoubleQuotedPrefix(value) {
            return String(value).replace(/(["\\$`])/g, "\\$1")
        }

        Timer {
            id: closeTimer
            interval: 180
            repeat: false
            onTriggered: win.frozenGroup = null
        }

        Timer {
            id: enableBehaviorTimer
            interval: 32
            repeat: false
            onTriggered: popup.behaviorEnabled = true
        }

        // ── Click-to-dismiss overlay ─────────────────────────────────────────
        MouseArea {
            anchors.fill: parent
            enabled: win.isOpen
            onClicked: {
                if (win.trayNavMode) BarNavigationService.closeTrayNav()
                else WhichKeyService.dismiss()
            }
        }

        // ── Keyboard capture ─────────────────────────────────────────────────
        Item {
            id: keyCapture
            focus: true

            Keys.onEscapePressed: {
                if (win.trayNavMode) {
                    BarNavigationService.closeTrayNav()
                    // WhichKey will dismiss via onTrayMenuClosed
                } else {
                    WhichKeyService.dismiss()
                }
            }

            Keys.onPressed: function(event) {
                if (!win.isOpen) return

                // ── Tray navigation mode: forward to TrayMenuPopup ────────────
                if (win.trayNavMode) {
                    const sc = Globals.scanCodes
                    switch (event.key) {
                    case Qt.Key_Up:
                        BarNavigationService.navigateUp()
                        event.accepted = true
                        break
                    case Qt.Key_Down:
                        BarNavigationService.navigateDown()
                        event.accepted = true
                        break
                    case Qt.Key_Left:
                        BarNavigationService.goBack()
                        event.accepted = true
                        break
                    case Qt.Key_Right:
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space:
                        BarNavigationService.activate()
                        event.accepted = true
                        break
                    case Qt.Key_Escape:
                        // handled by Keys.onEscapePressed above
                        break
                    default:
                        if (event.nativeScanCode === sc['Q']) {
                            BarNavigationService.closeTrayNav(); event.accepted = true
                        } else if (event.nativeScanCode === sc['H']) {
                            BarNavigationService.navigateDown(); event.accepted = true
                        } else if (event.nativeScanCode === sc['A']) {
                            BarNavigationService.navigateUp(); event.accepted = true
                        } else if (event.nativeScanCode === sc['E']) {
                            BarNavigationService.activate(); event.accepted = true
                        } else if (event.nativeScanCode === sc['Y']) {
                            BarNavigationService.goBack(); event.accepted = true
                        }
                        break
                    }
                    return
                }

                // ── Normal group handling ─────────────────────────────────────
                const grp = WhichKeyService.group
                const sc  = Globals.scanCodes

                if (grp === "window") {
                    if (event.nativeScanCode === sc['C']) {
                        win.runCommand("~/scripts/killactive.sh")
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['K']) {
                        win.runCommand("~/scripts/forcekillactive.sh")
                        event.accepted = true
                    }

                } else if (grp === "browser") {
                    if (event.nativeScanCode === sc['L']) {
                        win.runCommand("librewolf")
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['D']) {
                        win.runCommand('chromium --profile-directory="Profile 1"')
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['G']) {
                        win.runCommand('chromium --profile-directory="Default"')
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['C']) {
                        win.runCommand("chromium")
                        event.accepted = true
                    }

                } else if (grp === "picker") {
                    if (event.nativeScanCode === sc['B']) {
                        WhichKeyService.dismiss()
                        BluetoothPickerService.show()
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['W']) {
                        WhichKeyService.dismiss()
                        WallpaperSwitcherService.toggle()
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['P']) {
                        WhichKeyService.dismiss()
                        PassMenuService.toggle()
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['M']) {
                        WhichKeyService.dismiss()
                        VMPickerService.show()
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['V']) {
                        WhichKeyService.dismiss()
                        VPNPickerService.show()
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['O']) {
                        WhichKeyService.dismiss()
                        AudioOutputPickerService.show()
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['U']) {
                        WhichKeyService.dismiss()
                        EjectPickerService.show()
                        event.accepted = true
                    }

                } else if (grp === "bar") {
                    // Digit keys 1–9: XKB keycodes 10–18
                    if (event.nativeScanCode >= 10 && event.nativeScanCode <= 18) {
                        const idx = event.nativeScanCode - 10
                        const trayItems = SystemTray.items.values
                        if (idx >= trayItems.length || !trayItems[idx].hasMenu) return
                        win.trayNavMode = true
                        BarNavigationService.requestTrayMenu(idx)
                        event.accepted = true
                        // WhichKey stays open — keys are now forwarded to TrayMenuPopup
                    } else if (event.nativeScanCode === sc['N']) {
                        WhichKeyService.dismiss()
                        DashboardService.show(1)  // Inbox
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['C']) {
                        WhichKeyService.dismiss()
                        DashboardService.show(0)  // Controls
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['O']) {
                        WhichKeyService.dismiss()
                        DashboardService.show(2)  // Overview
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['M']) {
                        WhichKeyService.dismiss()
                        DashboardService.show(3)  // Media
                        event.accepted = true
                    }

                } else if (grp === "screen") {
                    const ts    = "$(date +%F_%H-%M-%S)"
                    const shots = "$HOME/Pictures/Screenshots"
                    const shotFile = `${shots}/${ts}-shot.png`
                    const screenshotAppName = win.shellQuote(Localization.t("notifications.screenshot.appName", "Screenshot"))
                    const cancelledTitle = win.shellQuote(Localization.t("notifications.screenshot.cancelled.title", "Screenshot cancelled"))
                    const savedTitle = win.shellQuote(Localization.t("notifications.screenshot.saved.title", "Screenshot saved"))
                    const multiMonitorBody = win.shellQuote(Localization.t("notifications.shared.selectionSpansMonitors", "Selection spans multiple monitors."))
                    const savedBodyPrefix = win.shellDoubleQuotedPrefix(Localization.t("notifications.shared.pathCopiedToClipboard", "Path copied to clipboard:"))
                    // Run slurp, then verify the selection fits inside a single
                    // monitor's logical bounds (via hyprctl + jq). If it spans
                    // multiple monitors, notify and abort. `payload` runs with
                    // $geom set to "X,Y WxH".
                    const guardedSlurp = (payload) =>
                        `geom=$(slurp ${Globals.slurpArgs}) || exit 1; ` +
                        `read X Y W H <<<"$(echo "$geom" | sed 's/[,x]/ /g')"; ` +
                        `if ! hyprctl monitors -j | jq -e --argjson x $X --argjson y $Y --argjson w $W --argjson h $H ` +
                            `'any(.[]; (.x <= $x) and (.y <= $y) and ((.x + (.width/.scale)) >= ($x+$w)) and ((.y + (.height/.scale)) >= ($y+$h)))' >/dev/null; then ` +
                            `notify-send -a ${screenshotAppName} ${cancelledTitle} ${multiMonitorBody}; exit 1; ` +
                        `fi; ` + payload
                    if (event.nativeScanCode === sc['C']) {
                        win.runCommand(guardedSlurp(`grim -g "$geom" - | wl-copy`))
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['A']) {
                        win.runCommand(guardedSlurp(`grim -g "$geom" - | satty -f -`))
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['S']) {
                        win.runCommand(guardedSlurp(`out="${shotFile}"; grim -g "$geom" "$out" && printf '%s' "$out" | wl-copy && notify-send -a ${screenshotAppName} ${savedTitle} "${savedBodyPrefix} $out"`))
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['R']) {
                        WhichKeyService.dismiss()
                        RecordingService.record("")
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['M']) {
                        WhichKeyService.dismiss()
                        RecordingService.record("--audio")
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['D']) {
                        const sinkMonitor = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name + ".monitor" : ""
                        WhichKeyService.dismiss()
                        RecordingService.record(sinkMonitor ? `--audio --audio-device "${sinkMonitor}"` : "--audio")
                        event.accepted = true
                    } else if (event.nativeScanCode === sc['X']) {
                        WhichKeyService.dismiss()
                        RecordingService.stop()
                        event.accepted = true
                    }
                }
            }
        }

        // ── Centered popup ───────────────────────────────────────────────────
        Item {
            anchors.centerIn: parent
            width: popup.width
            height: popup.height

            // Hidden when in tray-nav mode (TrayMenuPopup is visible instead)
            opacity: win.isOpen && !win.trayNavMode ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 80 } }

            MouseArea { anchors.fill: parent; enabled: !win.trayNavMode }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 4
                radius: 20; samples: 36; color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.4)
            }

            Rectangle {
                id: popup
                width: col.implicitWidth + 56
                height: col.implicitHeight + 28
                property bool behaviorEnabled: false
                Behavior on width  { enabled: popup.behaviorEnabled; NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                Behavior on height { enabled: popup.behaviorEnabled; NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                color: MatugenColors.md3.surface
                radius: Globals.componentRadius
                border.color: MatugenColors.md3.outline_variant
                border.width: 1

                ColumnLayout {
                    id: col
                    anchors.centerIn: parent
                    spacing: 10

                    // ── Title ────────────────────────────────────────────────
                    RowLayout {
                        spacing: 6

                        Text {
                            font.family: "Material Symbols Rounded"
                            font.variableAxes: ({ "FILL": 1 })
                            renderType: Text.NativeRendering
                            font.pixelSize: 13
                            color: MatugenColors.md3.primary
                            text: win.frozenGroup ? win.frozenGroup.icon : ""
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: win.frozenGroup ? win.frozenGroup.title : ""
                            font.pixelSize: 13
                            font.letterSpacing: 1
                            color: MatugenColors.md3.on_surface
                            opacity: 0.5
                        }
                    }

                    // ── Separator ────────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: ColorUtils.transparentize(MatugenColors.md3.outline_variant, 0.5)
                    }

                    // ── Key bindings ─────────────────────────────────────────
                    // GridLayout col 0 = badges (right-aligned, auto-sized to widest row),
                    //            col 1 = labels (all start on the same vertical line)
                    GridLayout {
                        columns: 2
                        columnSpacing: 14
                        rowSpacing: 7

                        Repeater {
                            model: win.frozenGroup ? win.frozenGroup.bindings : []
                            delegate: Item {
                                id: keyCell
                                required property var modelData
                                required property int index
                                Layout.row: index; Layout.column: 0
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                implicitHeight: 24
                                implicitWidth: badgesRow.implicitWidth

                                RowLayout {
                                    id: badgesRow
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Repeater {
                                        model: keyCell.modelData.keys ?? [keyCell.modelData.key]
                                        delegate: RowLayout {
                                            required property string modelData
                                            required property int    index
                                            spacing: 4

                                            Text {
                                                visible: index > 0
                                                text: ".."
                                                font.pixelSize: 11
                                                color: MatugenColors.md3.on_surface_variant
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Rectangle {
                                                implicitWidth:  kl.implicitWidth + 14
                                                implicitHeight: 24; radius: 5
                                                color: "transparent"
                                                border.color: ColorUtils.transparentize(MatugenColors.md3.primary, 0.4)
                                                border.width: 1
                                                Text {
                                                    id: kl; anchors.centerIn: parent
                                                    text: modelData
                                                    font.family: "DejaVu Sans Mono"
                                                    font.pixelSize: 15; font.bold: true
                                                    color: MatugenColors.md3.primary
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: win.frozenGroup ? win.frozenGroup.bindings : []
                            delegate: Text {
                                required property var modelData
                                required property int index
                                Layout.row: index; Layout.column: 1
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                text: modelData.label
                                font.pixelSize: 16
                                color: MatugenColors.md3.on_surface
                                opacity: 0.75
                            }
                        }
                    }
                }
            }
        }
    }
}
