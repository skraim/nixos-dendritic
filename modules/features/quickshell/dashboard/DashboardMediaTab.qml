import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import qs.services
import qs.utils

Item {
    id: root
    required property var win

    property alias contentImplicitHeight: tab3Col.implicitHeight

    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        contentHeight: tab3Col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: tab3Col
            width: parent.width
            spacing: 0

            // ── Vinyl + track info ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                spacing: 14

                Item {
                    id: smallVinyl
                    width: 88
                    height: 88
                    property real _angle: 0
                    property real _vel: 0

                    function syncSpin(animated) {
                        const targetVel = root.win.isPlaying ? (360.0 / 6000.0) : 0.0;
                        smallVelAnim.stop();
                        if (animated) {
                            smallVelAnim.duration = root.win.isPlaying ? 700 : 1800;
                            smallVelAnim.to = targetVel;
                            smallVelAnim.start();
                        } else {
                            smallVinyl._vel = targetVel;
                        }
                    }

                    Component.onCompleted: Qt.callLater(() => syncSpin(false))
                    onVisibleChanged: if (visible)
                        syncSpin(false)

                    NumberAnimation {
                        id: smallVelAnim
                        target: smallVinyl
                        property: "_vel"
                        easing.type: Easing.OutCubic
                    }
                    Connections {
                        target: root.win
                        function onIsPlayingChanged() {
                            smallVinyl.syncSpin(true);
                        }
                        function onActivePlayerChanged() {
                            Qt.callLater(() => smallVinyl.syncSpin(false));
                        }
                    }
                    Timer {
                        interval: 16
                        repeat: true
                        running: root.win.isOpen
                        onTriggered: {
                            smallVinyl._angle = (smallVinyl._angle + smallVinyl._vel * 16) % 360;
                            vinylRotator.rotation = smallVinyl._angle;
                        }
                    }

                    Item {
                        id: vinylRotator
                        anchors.fill: parent

                        Item {
                            id: vinylDisc
                            anchors.fill: parent

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: MatugenColors.md3.surface_variant
                            }
                            Image {
                                anchors.fill: parent
                                source: root.win.activeArtUrl
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Qt.rgba(0, 0, 0, 0.2)
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 78
                                height: 78
                                radius: 39
                                color: "transparent"
                                border.color: Qt.rgba(0, 0, 0, 0.30)
                                border.width: 1
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 62
                                height: 62
                                radius: 31
                                color: "transparent"
                                border.color: Qt.rgba(0, 0, 0, 0.25)
                                border.width: 1
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 46
                                height: 46
                                radius: 23
                                color: "transparent"
                                border.color: Qt.rgba(0, 0, 0, 0.20)
                                border.width: 1
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 30
                                height: 30
                                radius: 15
                                color: "transparent"
                                border.color: Qt.rgba(0, 0, 0, 0.15)
                                border.width: 1
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                radius: 7
                                color: MatugenColors.md3.surface
                                border.color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.8)
                                border.width: 1
                            }
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: vinylDisc.width
                                    height: vinylDisc.height
                                    radius: width / 2
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.85)
                        border.width: 1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 25

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            text: root.win.activePlayer ? (root.win.activePlayer?.trackTitle ?? "") : Localization.t("dashboard.media.empty.nothingPlaying", "Nothing playing")
                            font.pixelSize: root.win.activePlayer ? 20 : 17
                            font.letterSpacing: root.win.activePlayer ? 0.3 : 0
                            color: MatugenColors.md3.on_surface
                            opacity: root.win.activePlayer ? 1.0 : 0.3
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 19

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            text: root.win.activePlayer?.trackArtist ?? ""
                            font.pixelSize: 15
                            color: MatugenColors.md3.on_surface
                            opacity: text !== "" ? 0.55 : 0.0
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    Item {
                        implicitHeight: 6
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Rectangle {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: 8
                            readonly property bool avail: !!(root.win.activePlayer?.canGoPrevious)
                            color: avail && prevArea.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.3) : ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.5)
                            opacity: avail ? 1.0 : 0.3
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Rounded"
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                font.pixelSize: 18
                                color: MatugenColors.md3.on_surface
                                opacity: 0.8
                                text: "skip_previous"
                            }
                            MouseArea {
                                id: prevArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: parent.avail
                                cursorShape: parent.avail ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    root.win.activePlayer?.previous();
                                    root.win.mediaPosition = 0;
                                }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                width: 13
                                height: 13
                                radius: 3
                                z: 1
                                color: MatugenColors.md3.primary
                                opacity: root.win.tabHintMode ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "P"
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: MatugenColors.md3.on_primary
                                }
                            }
                        }
                        Rectangle {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: 10
                            readonly property bool avail: !!root.win.activePlayer
                            color: avail && playArea.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.35) : ColorUtils.transparentize(MatugenColors.md3.primary, 0.55)
                            opacity: avail ? 1.0 : 0.3
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Rounded"
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                font.pixelSize: 22
                                color: MatugenColors.md3.on_surface
                                text: root.win.isPlaying ? "pause" : "play_arrow"
                            }
                            MouseArea {
                                id: playArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: parent.avail
                                cursorShape: parent.avail ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.win.activePlayer?.togglePlaying()
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                width: 13
                                height: 13
                                radius: 3
                                z: 1
                                color: MatugenColors.md3.primary
                                opacity: root.win.tabHintMode ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "Spc"
                                    font.pixelSize: 6
                                    font.bold: true
                                    color: MatugenColors.md3.on_primary
                                }
                            }
                        }
                        Rectangle {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: 8
                            readonly property bool avail: !!(root.win.activePlayer?.canGoNext)
                            color: avail && nextArea.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.3) : ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.5)
                            opacity: avail ? 1.0 : 0.3
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Rounded"
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                font.pixelSize: 18
                                color: MatugenColors.md3.on_surface
                                opacity: 0.8
                                text: "skip_next"
                            }
                            MouseArea {
                                id: nextArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: parent.avail
                                cursorShape: parent.avail ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    root.win.activePlayer?.next();
                                    root.win.mediaPosition = 0;
                                }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                width: 13
                                height: 13
                                radius: 3
                                z: 1
                                color: MatugenColors.md3.primary
                                opacity: root.win.tabHintMode ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "N"
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: MatugenColors.md3.on_primary
                                }
                            }
                        }
                    }

                    // ── Player source selector ────────────────────────────────
                    RowLayout {
                        id: sourceSelectorRow
                        Layout.fillWidth: true
                        spacing: 4
                        Layout.topMargin: 4
                        readonly property bool multiPlayer: Mpris.players.values.length > 1
                        opacity: multiPlayer ? 1.0 : 0.35
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        Item {
                            implicitWidth: 20
                            implicitHeight: 20
                            Text {
                                anchors.centerIn: parent
                                text: "chevron_left"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                color: MatugenColors.md3.on_surface
                                opacity: prevPArea.containsMouse && sourceSelectorRow.multiPlayer ? 0.9 : 0.45
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 80
                                    }
                                }
                            }
                            MouseArea {
                                id: prevPArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: sourceSelectorRow.multiPlayer
                                cursorShape: sourceSelectorRow.multiPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    const ps = Mpris.players.values;
                                    const idx = ps.findIndex(p => p === root.win.activePlayer);
                                    root.win.selectedPlayerName = ps[(idx - 1 + ps.length) % ps.length].identity;
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 22
                            MouseArea {
                                id: playerLabelArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: sourceSelectorRow.multiPlayer
                                cursorShape: sourceSelectorRow.multiPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.win.playerDropdownOpen = !root.win.playerDropdownOpen
                            }
                            Text {
                                id: playerLabelText
                                anchors.centerIn: parent
                                text: root.win.activePlayer?.identity ?? Localization.t("dashboard.media.empty.noPlayer", "No player")
                                font.pixelSize: 12
                                color: MatugenColors.md3.on_surface
                                opacity: (playerLabelArea.containsMouse || root.win.playerDropdownOpen) && sourceSelectorRow.multiPlayer ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 100
                                    }
                                }
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                anchors.top: playerLabelText.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: playerLabelText.width
                                height: 1
                                color: MatugenColors.md3.on_surface
                                opacity: (playerLabelArea.containsMouse || root.win.playerDropdownOpen) && sourceSelectorRow.multiPlayer ? 0.6 : 0.25
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 100
                                    }
                                }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                width: 13
                                height: 13
                                radius: 3
                                z: 1
                                color: MatugenColors.md3.primary
                                opacity: root.win.tabHintMode ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "Tab"
                                    font.pixelSize: 6
                                    font.bold: true
                                    color: MatugenColors.md3.on_primary
                                }
                            }
                        }

                        Item {
                            implicitWidth: 20
                            implicitHeight: 20
                            Text {
                                anchors.centerIn: parent
                                text: "chevron_right"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                color: MatugenColors.md3.on_surface
                                opacity: nextPArea.containsMouse && sourceSelectorRow.multiPlayer ? 0.9 : 0.45
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 80
                                    }
                                }
                            }
                            MouseArea {
                                id: nextPArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: sourceSelectorRow.multiPlayer
                                cursorShape: sourceSelectorRow.multiPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    const ps = Mpris.players.values;
                                    const idx = ps.findIndex(p => p === root.win.activePlayer);
                                    root.win.selectedPlayerName = ps[(idx + 1) % ps.length].identity;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        visible: root.win.playerDropdownOpen
                        Repeater {
                            model: Mpris.players
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool isActive: modelData === root.win.activePlayer
                                Layout.fillWidth: true
                                implicitHeight: 24
                                radius: 5
                                color: isActive ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.45) : dropItemArea.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.35) : ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.60)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.identity
                                    font.pixelSize: 12
                                    color: MatugenColors.md3.on_surface
                                    opacity: isActive ? 1.0 : 0.60
                                }
                                MouseArea {
                                    id: dropItemArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.win.selectedPlayerName = modelData.identity;
                                        root.win.playerDropdownOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Cava + progress bar overlay ───────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                implicitHeight: 88

                readonly property bool progressVisible: {
                    const len = root.win.activePlayer?.length ?? 0;
                    return len > 0 && len < 86400;
                }

                Canvas {
                    id: cavaCanvas
                    anchors.fill: parent
                    property var bars: root.win.cavaBars
                    property color accentColor: MatugenColors.md3.primary
                    onBarsChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onAccentColorChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const bs = bars;
                        if (!bs || bs.length === 0)
                            return;
                        const mirrored = [...bs.slice().reverse(), ...bs];
                        const n = mirrored.length;
                        const gap = 2;
                        const barW = Math.max(1, (width - gap * (n - 1)) / n);
                        const c = accentColor;
                        for (let i = 0; i < n; i++) {
                            const v = mirrored[i];
                            const h = Math.max(2, v * height);
                            ctx.fillStyle = "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + (0.35 + v * 0.65).toFixed(2) + ")";
                            ctx.fillRect(i * (barW + gap), height - h, barW, h);
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 36
                    z: 2
                    visible: parent.progressVisible

                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: ColorUtils.transparentize(MatugenColors.md3.surface, 0.28)
                    }

                    ColumnLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: 3

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            Rectangle {
                                anchors.fill: parent
                                radius: 2
                                color: ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.82)
                            }
                            Rectangle {
                                height: parent.height
                                radius: 2
                                width: {
                                    const len = root.win.activePlayer?.length ?? 0;
                                    return len > 0 ? Math.max(radius * 2, (root.win.mediaPosition / len) * parent.width) : 0;
                                }
                                color: MatugenColors.md3.primary
                                Behavior on width {
                                    NumberAnimation {
                                        duration: 950
                                        easing.type: Easing.Linear
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function (mouse) {
                                    const len = root.win.activePlayer?.length ?? 0;
                                    if (len > 0 && root.win.activePlayer) {
                                        const pos = (mouse.x / width) * len;
                                        root.win.activePlayer.position = pos;
                                        root.win.mediaPosition = pos;
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: {
                                    const s = Math.floor(root.win.mediaPosition);
                                    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
                                }
                                font.pixelSize: 10
                                color: MatugenColors.md3.on_surface
                                opacity: 0.55
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Text {
                                text: {
                                    const s = Math.floor(root.win.activePlayer?.length ?? 0);
                                    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
                                }
                                font.pixelSize: 10
                                color: MatugenColors.md3.on_surface
                                opacity: 0.55
                            }
                        }
                    }
                }
            }

            Item {
                implicitHeight: 4
            }
        }
    }
}
