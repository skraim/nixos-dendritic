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
            visible: win.visible
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: win.isOpen ? 0.5 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: ClipHistService.dismiss()
            }
        }
    }

    PanelWindow {
        id: win

        property bool isOpen: false
        property int  currentTab:  0   // 0 = text, 1 = images
        property int  currentIndex: 0
        property var  textEntries:  []
        property var  imageEntries: []
        property bool isLoading:   false
        property bool previewOpen: false
        property string previewPath: ""
        property bool mouseActive: false
        property int  displayTab: 0     // lags currentTab through the switch animation
        property int  _fromTab:   0     // captured at animation start
        property int  _toTab:     0     // captured at animation start

        property var filteredText: {
            const q = searchInput.text.trim().toLowerCase()
            if (q.length === 0) return textEntries
            return textEntries.filter(e =>
                e.content.toLowerCase().includes(q) || String(e.pos).includes(q)
            )
        }
        property var filteredImages: {
            return imageEntries
        }

        visible: isOpen || closeTimer.running
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        anchors.top: true; anchors.bottom: true
        anchors.left: true; anchors.right: true

        Connections {
            target: ClipHistService
            function onVisibleChanged() {
                if (ClipHistService.visible) {
                    win.isOpen = true
                } else {
                    closeTimer.restart()
                    win.isOpen = false
                }
            }
        }

        onCurrentTabChanged: {
            if (!isOpen) return
            tabSwitchAnim.stop()
            _fromTab = displayTab
            _toTab   = currentTab
            textList.opacity  = displayTab === 0 ? 1.0 : 0.0
            imageList.opacity = displayTab === 1 ? 1.0 : 0.0
            tabSwitchAnim.start()
        }

        // Sequenced tab transition: fade out → resize → fade in
        SequentialAnimation {
            id: tabSwitchAnim
            NumberAnimation {
                target: win._fromTab === 0 ? textList : imageList
                property: "opacity"; to: 0.0; duration: 100; easing.type: Easing.InQuad
            }
            ScriptAction { script: win.displayTab = win._toTab }
            PauseAnimation { duration: 80 }
            NumberAnimation {
                target: win._toTab === 0 ? textList : imageList
                property: "opacity"; to: 1.0; duration: 100; easing.type: Easing.OutQuad
            }
        }

        onIsOpenChanged: {
            if (isOpen) {
                currentTab   = 0
                displayTab   = 0
                currentIndex = 0
                mouseActive  = false
                tabSwitchAnim.stop()
                textList.opacity  = 1.0
                imageList.opacity = 0.0
                textEntries  = []
                imageEntries = []
                previewOpen  = false
                previewPath  = ""
                searchInput.text = ""
                isLoading = true
                listProcess.running = true
                searchInput.forceActiveFocus()
            } else {
                previewOpen = false
            }
        }

        // ── Navigation & actions ────────────────────────────────────────────
        function navigate(delta) {
            mouseActive = false
            const arr = currentTab === 0 ? filteredText : filteredImages
            if (arr.length === 0) return
            currentIndex = (currentIndex + delta + arr.length) % arr.length
            // Update preview image when navigating while preview is open
            if (previewOpen && currentTab === 1) {
                const e = arr[currentIndex]
                if (e.previewPath) previewPath = "file://" + e.previewPath
            }
            // Ensure item stays visible
            Qt.callLater(function() {
                if (currentTab === 0) textList.positionViewAtIndex(currentIndex, ListView.Contain)
                else                  imageList.positionViewAtIndex(currentIndex, ListView.Contain)
            })
        }

        function activateCurrent() {
            if (currentTab === 0) {
                if (currentIndex >= 0 && currentIndex < filteredText.length)
                    copyEntry(filteredText[currentIndex].id)
            } else {
                if (currentIndex >= 0 && currentIndex < filteredImages.length)
                    copyEntry(filteredImages[currentIndex].id)
            }
        }

        function openPreview() {
            if (currentTab !== 1) return
            if (currentIndex >= 0 && currentIndex < filteredImages.length) {
                const e = filteredImages[currentIndex]
                if (e.previewPath) {
                    previewPath = "file://" + e.previewPath
                    previewOpen = true
                }
            }
        }

        function switchTab(tab) {
            currentTab   = tab
            currentIndex = 0
            mouseActive  = false
            if (tab === 0) searchInput.forceActiveFocus()
            else           imageFocus.forceActiveFocus()
        }

        function copyEntry(clipId) {
            Quickshell.execDetached(["bash", "-c",
                "cliphist list | grep -m1 --text '^" + clipId + "\t' | cliphist decode | wl-copy"
            ])
            ClipHistService.dismiss()
        }

        // Window-level Esc: close preview first, then popup
        Keys.onEscapePressed: {
            if (previewOpen) previewOpen = false
            else ClipHistService.dismiss()
        }

        // ── Focus item for image mode ────────────────────────────────────────
        Item {
            id: imageFocus
            Keys.onEscapePressed: {
                if (win.previewOpen) win.previewOpen = false
                else ClipHistService.dismiss()
            }
            Keys.onReturnPressed: win.activateCurrent()
            Keys.onUpPressed:     win.navigate(-1)
            Keys.onDownPressed:   win.navigate(1)
            Keys.onPressed: function(event) {
                const sc = Globals.scanCodes
                if (event.nativeScanCode === sc['P'] && !(event.modifiers & Qt.ControlModifier)) {
                    win.previewOpen ? win.previewOpen = false : win.openPreview()
                    event.accepted = true
                } else if (event.key === Qt.Key_Tab) {
                    win.switchTab(0); event.accepted = true
                } else if (event.modifiers & Qt.ControlModifier) {
                    if (event.nativeScanCode === sc['N']) { win.navigate(1);  event.accepted = true }
                    else if (event.nativeScanCode === sc['P']) { win.navigate(-1); event.accepted = true }
                }
            }
        }

        // ── List loader ─────────────────────────────────────────────────────
        Process {
            id: listProcess
            running: false
            command: ["bash", "-c",
                "emit() { case \"$content\" in " +
                "  '[[ binary'*) " +
                "    printf 'I\\t%s\\n' \"$id\"; " +
                "    printf '%s\\t%s\\n' \"$id\" \"$content\" | cliphist decode > \"/tmp/qs-clip-$id\" 2>/dev/null " +
                "      && printf 'D\\t%s\\n' \"$id\";; " +
                "  *) printf 'T\\t%s\\t%s\\n' \"$id\" \"$content\";; " +
                "esac; }; " +
                "id=''; content=''; " +
                "while IFS='' read -r line; do " +
                "  if [[ \"$line\" =~ ^([0-9]+)$'\\t'(.*) ]]; then " +
                "    [[ -n \"$id\" ]] && emit; " +
                "    id=\"${BASH_REMATCH[1]}\"; content=\"${BASH_REMATCH[2]}\"; " +
                "  elif [[ -n \"$id\" ]]; then " +
                "    content=\"${content}\"$'\\001'\"${line}\"; " +
                "  fi; " +
                "done < <(cliphist list 2>/dev/null); " +
                "[[ -n \"$id\" ]] && emit"
            ]
            stdout: SplitParser {
                onRead: function(line) {
                    const tab = line.indexOf('\t')
                    if (tab < 0) return
                    const type = line.substring(0, tab)
                    const rest = line.substring(tab + 1)
                    if (type === 'T') {
                        const tab2 = rest.indexOf('\t')
                        if (tab2 < 0) return
                        const id      = rest.substring(0, tab2)
                        const content = rest.substring(tab2 + 1)
                        const arr = win.textEntries.slice()
                        arr.push({id, content, pos: arr.length + 1})
                        win.textEntries = arr
                    } else if (type === 'I') {
                        const arr = win.imageEntries.slice()
                        arr.push({id: rest, previewPath: ''})
                        win.imageEntries = arr
                    } else if (type === 'D') {
                        win.imageEntries = win.imageEntries.map(e =>
                            e.id === rest
                                ? Object.assign({}, e, {previewPath: '/tmp/qs-clip-' + rest})
                                : e
                        )
                    }
                }
            }
            onRunningChanged: { if (!running) win.isLoading = false }
        }

        Timer {
            id: closeTimer
            interval: 220; repeat: false
            onTriggered: { textEntries = []; imageEntries = []; currentIndex = 0; previewOpen = false; previewPath = "" }
        }

        MouseArea { anchors.fill: parent; enabled: win.isOpen; onClicked: ClipHistService.dismiss() }

        // ── Center panel ────────────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.35)
            width: 900
            height: mainRect.height

            opacity: win.isOpen ? 1.0 : 0.0
            scale:   win.isOpen ? 1.0 : 0.96
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }
            HoverHandler { onPointChanged: win.mouseActive = true }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 2
                radius: 12; samples: 22; color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.5)
            }

            Rectangle {
                id: mainRect
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: panelCol.implicitHeight + 24
                color: MatugenColors.md3.surface
                radius: Globals.componentRadius
                clip: true

                ColumnLayout {
                    id: panelCol
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
                    spacing: 8

                    // ── Search bar + tab pill ───────────────────────────────
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
                                color: MatugenColors.md3.on_surface
                                opacity: win.currentTab === 0 ? 0.6 : 0.25
                                text: "\ue8b6"
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Search input (text mode)
                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.pixelSize: 16
                                color: MatugenColors.md3.on_surface
                                selectionColor: MatugenColors.md3.primary
                                clip: true
                                enabled: win.currentTab === 0
                                opacity: win.currentTab === 0 ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                onTextChanged: { win.currentIndex = 0; win.mouseActive = false }

                                Text {
                                    anchors.fill: parent
                                    text: Localization.t("cliphist.search", "Search clipboard...")
                                    font: searchInput.font
                                    color: MatugenColors.md3.on_surface; opacity: 0.3
                                    visible: searchInput.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Keys.onEscapePressed: {
                                    if (win.previewOpen) win.previewOpen = false
                                    else ClipHistService.dismiss()
                                }
                                Keys.onReturnPressed: win.activateCurrent()
                                Keys.onUpPressed:     win.navigate(-1)
                                Keys.onDownPressed:   win.navigate(1)
                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Tab) {
                                        win.switchTab(1); event.accepted = true
                                    } else if (event.modifiers & Qt.ControlModifier) {
                                        if (event.key === Qt.Key_N) {
                                            win.navigate(1);  event.accepted = true
                                        } else if (event.key === Qt.Key_P) {
                                            win.navigate(-1); event.accepted = true
                                        }
                                    }
                                }
                            }

                            // ── Tab pill ────────────────────────────────────
                            Rectangle {
                                implicitHeight: 30
                                implicitWidth: tabPillRow.implicitWidth + 6
                                radius: Globals.componentRadius - 4
                                color: MatugenColors.md3.surface_container_low

                                RowLayout {
                                    id: tabPillRow
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Rectangle {
                                        implicitWidth:  textTabLbl.implicitWidth + 20
                                        implicitHeight: 24
                                        radius: Globals.componentRadius - 6
                                        color: win.currentTab === 0
                                            ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4)
                                            : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            id: textTabLbl
                                            anchors.centerIn: parent
                                            text: Localization.t("cliphist.tabs.text", "Text") + (win.textEntries.length > 0 ? "  " + win.textEntries.length : "")
                                            font.pixelSize: 13
                                            color: MatugenColors.md3.on_surface
                                            opacity: win.currentTab === 0 ? 1.0 : 0.45
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: win.switchTab(0)
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth:  imgTabLbl.implicitWidth + 20
                                        implicitHeight: 24
                                        radius: Globals.componentRadius - 6
                                        color: win.currentTab === 1
                                            ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4)
                                            : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            id: imgTabLbl
                                            anchors.centerIn: parent
                                            text: Localization.t("cliphist.tabs.images", "Images") + (win.imageEntries.length > 0 ? "  " + win.imageEntries.length : "")
                                            font.pixelSize: 13
                                            color: MatugenColors.md3.on_surface
                                            opacity: win.currentTab === 1 ? 1.0 : 0.45
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: win.switchTab(1)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Image mode hint ─────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: win.displayTab === 1 ? 18 : 0
                        clip: true
                        Behavior on implicitHeight { NumberAnimation { duration: 80; easing.type: Easing.InOutQuad } }
                        Text {
                            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            text: Localization.t("cliphist.hints.preview", "P - preview")
                            font.pixelSize: 13
                            color: MatugenColors.md3.on_surface
                            opacity: win.displayTab === 1 ? 0.3 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutSine } }
                        }
                    }

                    // ── Lists (stacked, crossfade on tab switch) ─────────────
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: win.displayTab === 0
                            ? Math.min(win.filteredText.length, 10) * 44
                            : Math.min(win.filteredImages.length, 6) * 76
                        Behavior on implicitHeight {
                            NumberAnimation { duration: 80; easing.type: Easing.InOutQuad }
                        }

                        // ── Text list ──────────────────────────────────────
                        ListView {
                            id: textList
                            anchors.fill: parent
                            clip: true
                            model: win.filteredText
                            currentIndex: win.currentIndex
                            enabled: win.currentTab === 0

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: textList.width; height: 44
                                readonly property bool isSelected: index === win.currentIndex

                                Rectangle {
                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                                    color: isSelected
                                        ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.65) : "transparent"
                                    radius: Globals.componentRadius - 4
                                    Behavior on color { ColorAnimation { duration: 40 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 4; rightMargin: 10 }
                                        spacing: 18

                                        Text {
                                            text: modelData.pos
                                            font.pixelSize: 12
                                            color: MatugenColors.md3.on_surface; opacity: 0.3
                                            Layout.preferredWidth: 26
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            textFormat: Text.StyledText
                                            text: modelData.content.replace(
                                                /\x01/g,
                                                "<font color='" + MatugenColors.md3.primary + "'> ↵ </font>"
                                            )
                                            font.pixelSize: 14
                                            color: MatugenColors.md3.on_surface
                                            opacity: 0.85
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        id: txtArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { if (win.mouseActive) win.currentIndex = index }
                                        onClicked: win.copyEntry(modelData.id)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: win.currentTab === 0 && textList.contentHeight > textList.height
                            anchors { right: parent.right; rightMargin: 4; top: parent.top; bottom: parent.bottom }
                            width: 3; radius: 1.5
                            color: MatugenColors.md3.outline_variant
                            Rectangle {
                                width: parent.width
                                height: textList.height > 0
                                    ? Math.max(24, (textList.height / textList.contentHeight) * textList.height) : 0
                                y: textList.height > 0
                                    ? (textList.contentY / textList.contentHeight) * textList.height : 0
                                radius: parent.radius
                                color: MatugenColors.md3.on_surface_variant; opacity: 0.6
                            }
                        }

                        // ── Image list ─────────────────────────────────────
                        ListView {
                            id: imageList
                            anchors.fill: parent
                            clip: true
                            model: win.filteredImages
                            currentIndex: win.currentIndex
                            enabled: win.currentTab === 1

                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: imageList.width; height: 76
                                readonly property bool isSelected: index === win.currentIndex

                                Rectangle {
                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2; topMargin: 1; bottomMargin: 1 }
                                    color: isSelected
                                        ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.55) : "transparent"
                                    radius: Globals.componentRadius - 4
                                    Behavior on color { ColorAnimation { duration: 40 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 10; rightMargin: 14 }
                                        spacing: 12

                                        Rectangle {
                                            Layout.preferredWidth:  116
                                            Layout.preferredHeight: 64
                                            color: MatugenColors.md3.surface_container
                                            radius: 4
                                            clip: true

                                            Image {
                                                id: thumbImg
                                                anchors.fill: parent
                                                source: modelData.previewPath
                                                    ? ("file://" + modelData.previewPath) : ""
                                                fillMode: Image.PreserveAspectFit
                                                asynchronous: true
                                                smooth: true
                                                visible: status === Image.Ready
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                font.family: "Material Symbols Rounded"; font.pixelSize: 22
                                                font.variableAxes: ({ "FILL": 1 })                                        
                                                renderType: Text.NativeRendering
                                                color: MatugenColors.md3.on_surface; opacity: 0.18
                                                text: "image"
                                                visible: thumbImg.status !== Image.Ready
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: thumbImg.status === Image.Ready
                                                ? thumbImg.implicitWidth + " × " + thumbImg.implicitHeight
                                                : ""
                                            font.pixelSize: 13
                                            color: MatugenColors.md3.on_surface; opacity: 0.55
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        id: imgRowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { if (win.mouseActive) win.currentIndex = index }
                                        onClicked: win.copyEntry(modelData.id)
                                        onDoubleClicked: { win.currentIndex = index; win.openPreview() }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: win.currentTab === 1 && imageList.contentHeight > imageList.height
                            anchors { right: parent.right; rightMargin: 4; top: parent.top; bottom: parent.bottom }
                            width: 3; radius: 1.5
                            color: MatugenColors.md3.outline_variant
                            Rectangle {
                                width: parent.width
                                height: imageList.height > 0
                                    ? Math.max(24, (imageList.height / imageList.contentHeight) * imageList.height) : 0
                                y: imageList.height > 0
                                    ? (imageList.contentY / imageList.contentHeight) * imageList.height : 0
                                radius: parent.radius
                                color: MatugenColors.md3.on_surface_variant; opacity: 0.6
                            }
                        }
                    }

                }
            }
        }

        // ── Full-image preview overlay ───────────────────────────────────────
        Rectangle {
            id: previewOverlay
            anchors.fill: parent
            color: ColorUtils.transparentize(MatugenColors.md3.surface, 0.2)
            opacity: win.previewOpen ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Image {
                id: previewImg
                anchors.centerIn: parent
                width:  Math.min(previewOverlay.width  * 0.62, implicitWidth  > 0 ? implicitWidth  : previewOverlay.width)
                height: Math.min(previewOverlay.height * 0.62, implicitHeight > 0 ? implicitHeight : previewOverlay.height)
                source: win.previewPath
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true

                scale: win.previewOpen ? 1.0 : 0.88
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0; verticalOffset: 6
                    radius: 28; samples: 48; color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.2)
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: win.previewOpen = false
            }
        }
    }
}
