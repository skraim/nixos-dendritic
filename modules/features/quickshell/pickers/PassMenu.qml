import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
            visible: passWindow.visible
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: passWindow.isOpen ? 0.5 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: PassMenuService.dismiss()
            }
        }
    }

    PanelWindow {
        id: passWindow

        // ── State ─────────────────────────────────────────────────────────
        property bool isOpen: false
        property string activeTab: "general"   // "general" | "otp"
        property var passEntries: []

        // Extra picker popup state
        property bool extraPopupOpen: false
        property string extraPopupEntry: ""
        property var extraPopupItems: []
        property int extraPopupIndex: 0
        property bool mouseActive: false

        visible: isOpen || closeTimer.running
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        // ── Service wiring ────────────────────────────────────────────────
        Connections {
            target: PassMenuService
            function onVisibleChanged() {
                if (PassMenuService.visible) {
                    passWindow.isOpen = true
                } else {
                    closeTimer.restart()
                    passWindow.isOpen = false
                    passWindow.extraPopupOpen = false
                }
            }
        }

        onIsOpenChanged: {
            if (isOpen) {
                activeTab = "general"
                mouseActive = false
                passSearchInput.text = ""
                passList.currentIndex = 0
                passWindow.extraPopupOpen = false
                passSearchInput.forceActiveFocus()
                // Reload so newly generated entries are visible
                passWindow.passEntries = []
                passLoader.running = true
            }
        }

        Timer { id: closeTimer; interval: 220; repeat: false }

        Keys.onEscapePressed: PassMenuService.dismiss()

        onExtraPopupOpenChanged: {
            if (extraPopupOpen) extraKeyCapture.forceActiveFocus()
            else passSearchInput.forceActiveFocus()
        }

        // ── Entry loader (runs once at startup) ───────────────────────────
        Process {
            id: passLoader
            running: true
            command: ["sh", "-c",
                "find \"${PASSWORD_STORE_DIR}\" -type f -name '*.gpg' 2>/dev/null " +
                "| sed \"s|${PASSWORD_STORE_DIR}/||; s|\\.gpg$||\" | sort"
            ]
            stdout: SplitParser {
                onRead: function(line) {
                    if (line.length > 0) {
                        const p = [...passWindow.passEntries]
                        p.push(line)
                        passWindow.passEntries = p
                    }
                }
            }
        }

        // ── Extra loader (pass show for popup) ────────────────────────────
        Process {
            id: passExtraLoader
            property string entry: ""
            property var rawLines: []
            running: false
            command: ["pass", "show", entry]

            onRunningChanged: {
                if (!running && rawLines.length > 0) {
                    var items = [{ label: "password", displayLabel: Localization.t("passMenu.extra.password", "password"), value: rawLines[0] }]
                    for (var i = 1; i < rawLines.length; i++) {
                        var line = rawLines[i]
                        var colonIdx = line.indexOf(':')
                        if (colonIdx > 0) {
                            var key = line.substring(0, colonIdx).trim()
                            var val = line.substring(colonIdx + 1).trim()
                            if (key.length > 0)
                                items.push({ label: key, value: val })
                        }
                    }
                    passWindow.extraPopupItems = items
                    passWindow.extraPopupIndex = 0
                    passWindow.extraPopupOpen = true
                }
            }

            stdout: SplitParser {
                onRead: function(line) {
                    passExtraLoader.rawLines = [...passExtraLoader.rawLines, line]
                }
            }
        }

        function executePass(entry) {
            const cmd = "pass_cmd=show;" +
                        " pass show " + JSON.stringify(entry) + " | grep -q '^otpauth://' && pass_cmd=otp;" +
                        " pass $pass_cmd " + JSON.stringify(entry) +
                        " | { IFS= read -r p; printf %s \"$p\"; } | wl-copy --sensitive" +
                        " && ydotool key 29:1 47:1 47:0 29:0"
            Quickshell.execDetached(["bash", "-c", cmd])
        }

        function openExtraPopup() {
            const entry = content.currentEntries[passList.currentIndex]
            if (!entry) return
            passWindow.extraPopupEntry = entry
            passWindow.extraPopupIndex = 0
            if (passWindow.activeTab === "otp") {
                passWindow.extraPopupItems = [{ label: "OTP", displayLabel: Localization.t("passMenu.tabs.otp", "OTP"), value: null }]
                passWindow.extraPopupOpen = true
            } else {
                passExtraLoader.rawLines = []
                passExtraLoader.entry = entry
                passExtraLoader.running = false
                passExtraLoader.running = true
            }
        }

        function copyExtra(item) {
            if (item.value === null) {
                // OTP: run pass otp and pipe to clipboard
                Quickshell.execDetached(["bash", "-c",
                    "pass otp " + JSON.stringify(passWindow.extraPopupEntry) + " | wl-copy --sensitive"])
            } else {
                // Single-quote the value to prevent any shell expansion of $, backticks, etc.
                const escaped = "'" + item.value.replace(/'/g, "'\\''") + "'"
                Quickshell.execDetached(["bash", "-c",
                    "printf '%s' " + escaped + " | wl-copy --sensitive"])
            }
            passWindow.extraPopupOpen = false
            PassMenuService.dismiss()
        }

        MouseArea { anchors.fill: parent; enabled: passWindow.isOpen; onClicked: PassMenuService.dismiss() }

        // ── Extra popup key capture ───────────────────────────────────────
        Item {
            id: extraKeyCapture
            Keys.onPressed: function(event) {
                const sc = Globals.scanCodes
                if (event.key === Qt.Key_Escape) {
                    passWindow.extraPopupOpen = false
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    const item = passWindow.extraPopupItems[passWindow.extraPopupIndex]
                    if (item) passWindow.copyExtra(item)
                } else if (event.key === Qt.Key_Up || event.nativeScanCode === sc['A']
                        || ((event.modifiers & Qt.ControlModifier) && event.nativeScanCode === sc['P'])) {
                    passWindow.extraPopupIndex = passWindow.extraPopupIndex > 0
                        ? passWindow.extraPopupIndex - 1
                        : Math.max(passWindow.extraPopupItems.length - 1, 0)
                } else if (event.key === Qt.Key_Down || event.nativeScanCode === sc['H']
                        || ((event.modifiers & Qt.ControlModifier) && event.nativeScanCode === sc['N'])) {
                    passWindow.extraPopupIndex = passWindow.extraPopupIndex < passWindow.extraPopupItems.length - 1
                        ? passWindow.extraPopupIndex + 1 : 0
                }
                event.accepted = true
            }
        }

        // ── Center panel ──────────────────────────────────────────────────
        Item {
            id: panel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.35)
            width: 720
            height: mainRect.height

            opacity: passWindow.isOpen ? 1.0 : 0.0
            scale:   passWindow.isOpen ? 1.0 : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }
            HoverHandler { onPointChanged: passWindow.mouseActive = true }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 2
                radius: 12; samples: 22; color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.5)
            }

            Rectangle {
                id: mainRect
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: content.implicitHeight + 24
                color: MatugenColors.md3.surface
                radius: Globals.componentRadius
                clip: true

                ColumnLayout {
                    id: content
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
                    spacing: 8

                    // ── Computed lists ────────────────────────────────────
                    property var filteredGeneral: {
                        const q = passSearchInput.text.trim().toLowerCase()
                        const base = passWindow.passEntries.filter(e => !e.startsWith("otp/"))
                        return q.length === 0 ? base : base.filter(e => e.toLowerCase().includes(q))
                    }

                    property var filteredOtp: {
                        const q = passSearchInput.text.trim().toLowerCase()
                        const base = passWindow.passEntries.filter(e => e.startsWith("otp/"))
                        return q.length === 0 ? base : base.filter(e => e.toLowerCase().includes(q))
                    }

                    property var currentEntries: passWindow.activeTab === "general"
                        ? filteredGeneral : filteredOtp

                    // ── Search bar + tab toggle ───────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        color: MatugenColors.md3.surface_container
                        radius: Globals.componentRadius

                        RowLayout {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            spacing: 10

                            Text {
                                font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                font.variableAxes: ({ "FILL": 1 })
                                renderType: Text.NativeRendering
                                color: MatugenColors.md3.on_surface; opacity: 0.6
                                text: passWindow.activeTab === "otp" ? "123" : "lock"
                            }

                            TextInput {
                                id: passSearchInput
                                Layout.fillWidth: true
                                font.pixelSize: 16
                                color: MatugenColors.md3.on_surface
                                selectionColor: MatugenColors.md3.primary
                                clip: true
                                onTextChanged: { passList.currentIndex = 0; passWindow.mouseActive = false }

                                Text {
                                    anchors.fill: parent
                                    text: Localization.t("passMenu.search", "Search passwords..."); font: passSearchInput.font
                                    color: MatugenColors.md3.on_surface; opacity: 0.3
                                    visible: passSearchInput.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Keys.onEscapePressed: PassMenuService.dismiss()
                                Keys.onUpPressed: {
                                    passWindow.mouseActive = false
                                    passList.currentIndex = passList.currentIndex > 0
                                        ? passList.currentIndex - 1
                                        : Math.max(passList.count - 1, 0)
                                }
                                Keys.onDownPressed: {
                                    passWindow.mouseActive = false
                                    passList.currentIndex = passList.currentIndex < passList.count - 1
                                        ? passList.currentIndex + 1 : 0
                                }
                                Keys.onPressed: function(event) {
                                    const sc = Globals.scanCodes
                                    if (event.key === Qt.Key_Tab) {
                                        passWindow.activeTab = passWindow.activeTab === "general" ? "otp" : "general"
                                        passList.currentIndex = 0
                                        event.accepted = true
                                    } else if (event.modifiers & Qt.ControlModifier) {
                                        if (event.nativeScanCode === sc['N']) {
                                            passWindow.mouseActive = false
                                            passList.currentIndex = passList.currentIndex < passList.count - 1
                                                ? passList.currentIndex + 1 : 0
                                            event.accepted = true
                                        } else if (event.nativeScanCode === sc['P']) {
                                            passWindow.mouseActive = false
                                            passList.currentIndex = passList.currentIndex > 0
                                                ? passList.currentIndex - 1
                                                : Math.max(passList.count - 1, 0)
                                            event.accepted = true
                                        } else if (event.nativeScanCode === sc['G']) {
                                            if (passWindow.activeTab === "otp")
                                                PassGenerateService.scanOtp()
                                            else
                                                PassGenerateService.generatePass()
                                            event.accepted = true
                                        } else if (event.nativeScanCode === sc['E']) {
                                            passWindow.openExtraPopup()
                                            event.accepted = true
                                        }
                                    }
                                }
                                Keys.onReturnPressed: {
                                    const entry = content.currentEntries[passList.currentIndex]
                                    if (entry) {
                                        passWindow.executePass(entry)
                                        PassMenuService.dismiss()
                                    }
                                }
                            }

                            // General | OTP tab pill
                            Rectangle {
                                implicitHeight: 30
                                implicitWidth: tabRow.implicitWidth + 6
                                radius: Globals.componentRadius - 4
                                color: MatugenColors.md3.surface_container_low

                                RowLayout {
                                    id: tabRow
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Rectangle {
                                        implicitWidth: generalLbl.implicitWidth + 20
                                        implicitHeight: 24
                                        radius: Globals.componentRadius - 6
                                        color: passWindow.activeTab === "general"
                                            ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4)
                                            : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            id: generalLbl; anchors.centerIn: parent
                                            text: Localization.t("passMenu.tabs.general", "General"); font.pixelSize: 13
                                            color: MatugenColors.md3.on_surface
                                            opacity: passWindow.activeTab === "general" ? 1.0 : 0.45
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                passWindow.activeTab = "general"
                                                passList.currentIndex = 0
                                                passSearchInput.forceActiveFocus()
                                            }
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: otpLbl.implicitWidth + 20
                                        implicitHeight: 24
                                        radius: Globals.componentRadius - 6
                                        color: passWindow.activeTab === "otp"
                                            ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4)
                                            : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            id: otpLbl; anchors.centerIn: parent
                                            text: Localization.t("passMenu.tabs.otp", "OTP"); font.pixelSize: 13
                                            color: MatugenColors.md3.on_surface
                                            opacity: passWindow.activeTab === "otp" ? 1.0 : 0.45
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                passWindow.activeTab = "otp"
                                                passList.currentIndex = 0
                                                passSearchInput.forceActiveFocus()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Hint ──────────────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 18
                        Row {
                            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            spacing: 16
                            Text {
                                text: Localization.t("passMenu.hints.extra", "^E - extra")
                                font.pixelSize: 13
                                color: MatugenColors.md3.on_surface
                                opacity: 0.3
                            }
                            Text {
                                text: Localization.t("passMenu.hints.generate", "^G - generate")
                                font.pixelSize: 13
                                color: MatugenColors.md3.on_surface
                                opacity: 0.3
                            }
                        }
                    }

                    // ── Password list ─────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        clip: true
                        implicitHeight: Math.min(content.currentEntries.length, 10) * 46
                        Behavior on implicitHeight {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }

                        ListView {
                            id: passList
                            anchors.fill: parent
                            clip: true
                            model: content.currentEntries
                            currentIndex: 0
                            highlightMoveDuration: 0

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: passList.width; height: 46

                                Rectangle {
                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                                    color: index === passList.currentIndex
                                        ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
                                    radius: Globals.componentRadius - 4
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                        spacing: 12

                                        Text {
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 20
                                            font.variableAxes: ({ "FILL": 1 })
                                            renderType: Text.NativeRendering
                                            color: MatugenColors.md3.primary; opacity: 0.7
                                            text: passWindow.activeTab === "otp" ? "123" : "lock"
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData
                                            font.pixelSize: 15; color: MatugenColors.md3.on_surface
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: rowArea; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onEntered: { if (passWindow.mouseActive) passList.currentIndex = index }
                                        onClicked: {
                                            passWindow.executePass(modelData)
                                            PassMenuService.dismiss()
                                        }
                                    }
                                }
                            }
                        }

                        // Scroll indicator
                        Rectangle {
                            visible: passList.contentHeight > passList.height
                            anchors { right: parent.right; rightMargin: 4; top: parent.top; bottom: parent.bottom }
                            width: 3; radius: 1.5
                            color: MatugenColors.md3.outline_variant

                            Rectangle {
                                width: parent.width
                                height: passList.height > 0
                                    ? Math.max(24, (passList.height / passList.contentHeight) * passList.height) : 0
                                y: passList.height > 0
                                    ? (passList.contentY / passList.contentHeight) * passList.height : 0
                                radius: parent.radius
                                color: MatugenColors.md3.on_surface_variant
                                opacity: 0.6
                            }
                        }
                    }
                }
            }

        }

        // ── Extra picker popup ────────────────────────────────────────────
        // Sibling of panel (after it → renders on top), outside panel's layer
        Rectangle {
            id: extraPopup
            width: 260
            // panel.y + content top-margin(12) + search(44) + spacing(8) + hint(18) + spacing(8) = +90
            x: panel.x + 12
            y: panel.y + 90 + (passList.currentIndex + 1) * 46 - passList.contentY + 6
            height: extraPopupCol.implicitHeight + 24
            color: MatugenColors.md3.surface_container_low
            radius: Globals.componentRadius
            // drive visibility from state directly so it's true before the first animation tick
            visible: passWindow.extraPopupOpen || opacity > 0
            opacity: passWindow.extraPopupOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            // Subtle border
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: parent.radius
                border.width: 1
                border.color: ColorUtils.transparentize(MatugenColors.md3.outline_variant, 0.5)
            }

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                id: extraPopupCol
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
                spacing: 6

                // Title
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    Text {
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        text: Localization.t("passMenu.extra.copyToClipboard", "Copy to clipboard")
                        font.pixelSize: 12
                        color: MatugenColors.md3.on_surface
                        opacity: 0.45
                    }
                }

                // Extra items
                Repeater {
                    model: passWindow.extraPopupItems
                    delegate: Item {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 42

                        Rectangle {
                            anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                            color: index === passWindow.extraPopupIndex
                                ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
                            radius: Globals.componentRadius - 4
                            Behavior on color { ColorAnimation { duration: 80 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10

                                Text {
                                    font.family: "Material Symbols Rounded"; font.pixelSize: 18
                                    font.variableAxes: ({ "FILL": 1 })
                                    renderType: Text.NativeRendering
                                    color: MatugenColors.md3.primary; opacity: 0.7
                                    text: modelData.label === "password" ? "\ue897"
                                        : modelData.label === "OTP" ? "card_travel"
                                        : "\ue88f" // content_copy
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.displayLabel || modelData.label
                                    font.pixelSize: 14
                                    color: MatugenColors.md3.on_surface
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: extraRowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: { if (passWindow.mouseActive) passWindow.extraPopupIndex = index }
                                onClicked: passWindow.copyExtra(modelData)
                            }
                        }
                    }
                }

                // Bottom padding item
                Item { implicitHeight: 4 }
            }
        }
    }
}
