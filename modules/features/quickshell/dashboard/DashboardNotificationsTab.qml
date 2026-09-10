import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.utils

Item {
    id: root
    required property var win

    property bool listSettling: false

    function resetState() {
        listSettleTimer.stop();
        listSettling = false;
        root.win.expandedNotifIds = [];
        root.win.notifFocused = false;
        root.win.notifFocusIdx = -1;
        root.win.notifSelectionSource = "keyboard";
        root.win.notifHintMode = false;
        root.win.tabHintMode = false;
        if (tab1Flickable)
            tab1Flickable.contentY = 0;
    }

    function markListSettling() {
        listSettling = true;
        listSettleTimer.restart();
    }

    Timer {
        id: listSettleTimer
        interval: 260
        repeat: false
        onTriggered: root.listSettling = false
    }


    // ── Sub-components ────────────────────────────────────────────────────────

    component ExpandingNotifText: Item {
        id: et
        property string displayText: ""
        property bool expanded: false
        property int collapsedLines: 1
        property int pixelSize: 13
        property int fontWeight: Font.Normal
        property real textOpacity: 1.0

        readonly property bool hasText: et.displayText !== ""
        readonly property bool isTruncated: et.hasText && fullText.implicitHeight > collapsedMeasure.implicitHeight + 1

        Layout.fillWidth: true
        visible: et.hasText
        clip: true
        implicitHeight: !et.hasText ? 0 : et.expanded ? fullText.implicitHeight : collapsedMeasure.implicitHeight
        Behavior on implicitHeight {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: fullText
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            text: et.displayText
            textFormat: Text.StyledText
            font.family: "DejaVu Sans"
            font.pixelSize: et.pixelSize
            font.weight: et.fontWeight
            color: MatugenColors.md3.on_surface
            opacity: et.textOpacity
            wrapMode: Text.Wrap
        }

        Text {
            id: collapsedMeasure
            width: parent.width
            text: et.displayText
            textFormat: Text.StyledText
            font.family: "DejaVu Sans"
            font.pixelSize: et.pixelSize
            font.weight: et.fontWeight
            wrapMode: Text.Wrap
            maximumLineCount: et.collapsedLines
            visible: false
        }

    }

    component NotifCard: Item {
        id: nc
        property var notif
        property bool showDismiss: true
        property bool kbFocused: false
        property bool inner: false
        property bool contentExpanded: false
        property bool closing: false
        signal dismissRequested
        signal closeAnimationFinished
        signal hoverStarted
        signal hoverEnded
        signal toggleBodyRequested
        readonly property int actionColumnWidth: Math.max(40, Math.min(56, Math.round((nc.width - 20) * 0.12)))
        readonly property int actionCornerRadius: Globals.componentRadius - 3
        readonly property bool _hovered: ncHover.hovered
        readonly property bool hoverSelected: nc._hovered && root.win.notifSelectionSource === "mouse"
        readonly property bool selected: nc.kbFocused || nc.hoverSelected
        readonly property bool hasActionColumn: nc.showDismiss && nc.selected
        readonly property int reservedActionColumnWidth: nc.showDismiss ? nc.actionColumnWidth : 0
        property real actionButtonOffset: nc.hasActionColumn ? 0 : nc.actionColumnWidth
        property real lastPointerSceneX: -1
        property real lastPointerSceneY: -1
        onClosingChanged: if (nc.closing)
            closeAnimationTimer.restart()

        Layout.fillWidth: true
        implicitHeight: Math.max(72, ncRow.implicitHeight + 24)
        opacity: nc.closing ? 0.0 : 1.0
        clip: nc.closing
        Behavior on height {
            enabled: nc.closing
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
        Behavior on actionButtonOffset {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        readonly property color cardBaseColor: nc.selected ? ColorUtils.transparentize(MatugenColors.md3.surface_container_highest, 0.18)
            : ColorUtils.transparentize(MatugenColors.md3.surface_container_high, nc.inner ? 0.68 : 0.58)
        HoverHandler {
            id: ncHover
            onHoveredChanged: {
                if (hovered) {
                    nc.lastPointerSceneX = point.scenePosition.x;
                    nc.lastPointerSceneY = point.scenePosition.y;
                    nc.hoverStarted();
                } else {
                    nc.hoverEnded();
                }
            }
            onPointChanged: {
                if (hovered) {
                    const dx = Math.abs(point.scenePosition.x - nc.lastPointerSceneX);
                    const dy = Math.abs(point.scenePosition.y - nc.lastPointerSceneY);
                    nc.lastPointerSceneX = point.scenePosition.x;
                    nc.lastPointerSceneY = point.scenePosition.y;
                    if (dx > 0.5 || dy > 0.5)
                        nc.hoverStarted();
                }
            }
        }

        Timer {
            id: closeAnimationTimer
            interval: 190
            repeat: false
            onTriggered: if (nc.closing)
                nc.closeAnimationFinished()
        }

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                rightMargin: nc.reservedActionColumnWidth
            }
            topLeftRadius: nc.actionCornerRadius
            bottomLeftRadius: nc.actionCornerRadius
            topRightRadius: nc.showDismiss ? 0 : nc.actionCornerRadius
            bottomRightRadius: nc.showDismiss ? 0 : nc.actionCornerRadius
            color: nc.cardBaseColor
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            cursorShape: Qt.PointingHandCursor
            onClicked: nc.toggleBodyRequested()
        }

        RowLayout {
            id: ncRow
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            anchors.leftMargin: 10
            anchors.rightMargin: 10 + nc.reservedActionColumnWidth
            anchors.topMargin: 12
            spacing: 10

            Item {
                Layout.preferredWidth: Math.max(42, Math.round((nc.width - 20) * 0.15))
                Layout.minimumWidth: 42
                Layout.maximumWidth: 64
                Layout.fillHeight: true
                implicitHeight: 42
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: Math.min(parent.width, 52)
                    height: width
                    anchors.centerIn: parent
                    radius: 8
                    color: nc.notif?.urgency === 2 ? ColorUtils.transparentize(MatugenColors.md3.error, 0.45) : ColorUtils.transparentize(MatugenColors.md3.primary, 0.55)
                    visible: !ncNotifImg.visible && !ncAppImg.visible
                    Text {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        font.variableAxes: ({
                                "FILL": 1
                            })
                        renderType: Text.NativeRendering
                        color: MatugenColors.md3.on_surface
                        text: "\ue7f4"
                    }
                }

                Rectangle {
                    width: Math.min(parent.width, 52)
                    height: width
                    anchors.centerIn: parent
                    radius: 8
                    color: "transparent"
                    clip: true
                    Image {
                        id: ncNotifImg
                        anchors.fill: parent
                        source: {
                            const img = nc.notif?.image || "";
                            if (!img.startsWith("image://icon/"))
                                return img;
                            const iconName = img.substring(13);
                            const p = Quickshell.iconPath(iconName, false);
                            if (p.length > 0 && !p.startsWith("image://"))
                                return p;
                            const fallback = Settings.appIcons[iconName] || Settings.appIcons[iconName.toLowerCase()];
                            if (fallback) {
                                if (fallback.startsWith("file://") || fallback.startsWith("/"))
                                    return fallback;
                                return "file://" + Quickshell.shellDir + "/" + fallback;
                            }
                            return img;
                        }
                        sourceSize: Qt.size(56, 56)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: status === Image.Ready
                    }
                    Image {
                        id: ncAppImg
                        anchors.fill: parent
                        anchors.margins: 4
                        source: (nc.notif?.appIcon && !ncNotifImg.visible) ? "image://icon/" + nc.notif.appIcon : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: status === Image.Ready && !ncNotifImg.visible
                    }
                }
            }

            ColumnLayout {
                id: contentColumn
                Layout.preferredWidth: Math.max(120, Math.round((nc.width - 20) * 0.75))
                Layout.fillWidth: true
                spacing: 1
                ExpandingNotifText {
                    id: summaryText
                    displayText: (nc.notif?.summary || "").replace(/\n/g, "<br>")
                    expanded: nc.contentExpanded
                    collapsedLines: 2
                    pixelSize: 16
                    fontWeight: Font.DemiBold
                    textOpacity: 1.0
                }
                ExpandingNotifText {
                    id: bodyText
                    displayText: (nc.notif?.body || "").replace(/\n/g, "<br>")
                    expanded: nc.contentExpanded
                    collapsedLines: 4
                    pixelSize: 13
                    textOpacity: 0.65
                }
                RowLayout {
                    id: metadataRow
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: (nc.notif?.appName || "") + "  ·  " + (nc.notif?.timeStr || "")
                        font.family: "DejaVu Sans"
                        font.pixelSize: 12
                        color: MatugenColors.md3.on_surface
                        opacity: 0.35
                        elide: Text.ElideRight
                    }
                }
            }

        }

        Text {
            readonly property bool shown: !nc.contentExpanded && (summaryText.isTruncated || bodyText.isTruncated)
            x: nc.width - nc.reservedActionColumnWidth + nc.actionButtonOffset - implicitWidth - 6
            y: ncRow.y + contentColumn.y + metadataRow.y + Math.max(0, (metadataRow.height - height) / 2)
            visible: shown || opacity > 0.01
            text: "..."
            font.family: "DejaVu Sans"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: MatugenColors.md3.on_surface
            opacity: shown ? 0.55 : 0.0
            z: 8
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            id: actionColumn
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
            width: nc.reservedActionColumnWidth
            clip: true

            Item {
                id: dismissBtn
                x: nc.actionButtonOffset
                width: parent.width
                height: parent.height
                anchors.top: parent.top
                visible: nc.showDismiss
                opacity: nc.hasActionColumn ? 1.0 : 0.0
                z: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: 0
                    bottomLeftRadius: 0
                    topRightRadius: nc.actionCornerRadius
                    bottomRightRadius: nc.actionCornerRadius
                    color: dismissXArea.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.error, 0.45) : ColorUtils.transparentize(MatugenColors.md3.error, 0.78)
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    font.variableAxes: ({
                            "FILL": 1
                        })
                    renderType: Text.NativeRendering
                    color: MatugenColors.md3.on_surface
                    opacity: dismissXArea.containsMouse ? 0.9 : 0.58
                    text: "close"
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 80
                        }
                    }
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                        rightMargin: 4
                        bottomMargin: 4
                    }
                    width: 16
                    height: 16
                    radius: 3
                    z: 2
                    color: MatugenColors.md3.primary
                    opacity: root.win.notifHintMode && nc.hasActionColumn ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "X"
                        font.pixelSize: 9
                        font.bold: true
                        color: MatugenColors.md3.on_primary
                    }
                }

                MouseArea {
                    id: dismissXArea
                    anchors.fill: parent
                    enabled: nc.hasActionColumn
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        nc.dismissRequested();
                    }
                }
            }

        }

        Rectangle {
            anchors.fill: parent
            radius: nc.actionCornerRadius
            color: "transparent"
            border.width: 1
            border.color: nc.notif?.urgency === 2 ? ColorUtils.transparentize(MatugenColors.md3.error, 0.45) : ColorUtils.transparentize(MatugenColors.md3.outline, 0.78)
            opacity: nc.selected ? 0.95 : 0.72
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
            z: 30
        }
    }

    component NotifItem: NotifCard {
        id: ni
        property int itemIndex: -1

        width: parent ? parent.width : 0
        height: closing ? 0 : implicitHeight
        showDismiss: true
        closing: root.win.notificationClosing(ni.notif)
        kbFocused: root.win.notifFocused && root.win.notifFocusIdx === ni.itemIndex
        contentExpanded: root.win.expandedNotifIds.includes(root.win.notificationId(ni.notif))

        function focusY() {
            return 0;
        }

        function focusHeight() {
            return ni.height;
        }

        onHoverStarted: {
            root.win.notifSelectionSource = "mouse";
            root.win.notifFocused = true;
            root.win.notifFocusIdx = ni.itemIndex;
        }
        onHoverEnded: {
            if (root.win.notifSelectionSource !== "mouse" || root.win.notifFocusIdx !== ni.itemIndex)
                return;
            root.win.notifFocused = false;
            root.win.notifFocusIdx = -1;
            root.win.notifSelectionSource = "keyboard";
        }
        onToggleBodyRequested: {
            root.win.toggleNotificationBody(ni.notif);
        }
        onDismissRequested: {
            root.markListSettling();
            root.win.requestDismissNotification(ni.notif);
        }
        onCloseAnimationFinished: {
            root.markListSettling();
            root.win.finishDismissNotification(root.win.notificationId(ni.notif));
        }
    }

    // ── Tab content ───────────────────────────────────────────────────────────

    ColumnLayout {
        id: tab1Col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 0

        Connections {
            target: root.win
            function scrollFocusedNotificationIntoView() {
                if (root.win.notifFocusIdx < 0) {
                    return;
                }
                const item = notifRepeater.itemAt(root.win.notifFocusIdx);
                if (!item) {
                    return;
                }
                const itemY = item.y + item.focusY();
                const itemBot = itemY + item.focusHeight();
                const viewTop = tab1Flickable.contentY;
                const viewBot = viewTop + tab1Flickable.height;
                if (itemY < viewTop)
                    tab1Flickable.contentY = Math.max(0, itemY - 8);
                else if (itemBot > viewBot)
                    tab1Flickable.contentY = itemBot - tab1Flickable.height + 8;
            }
            function onNotifFocusIdxChanged() {
                scrollFocusedNotificationIntoView();
            }
            function onExpandedNotifIdsChanged() {
                Qt.callLater(scrollFocusedNotificationIntoView);
            }
            function onClosingNotifIdsChanged() {
                root.markListSettling();
            }
        }

        RowLayout {
            width: parent.width
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 6
            spacing: 6
            Item {
                Layout.fillWidth: true
            }

            Item {
                id: clearAllWrapper
                readonly property bool hasNotifications: root.win.notifItems.length > 0
                visible: hasNotifications || opacity > 0.01
                Layout.preferredWidth: clearAllPill.implicitWidth
                Layout.preferredHeight: clearAllPill.implicitHeight
                implicitWidth: clearAllPill.implicitWidth
                implicitHeight: clearAllPill.implicitHeight
                opacity: hasNotifications ? 1.0 : 0.0
                clip: false
                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }
                Rectangle {
                    id: clearAllPill
                    implicitWidth: clearAllLbl.implicitWidth + 16
                    implicitHeight: 24
                    radius: 5
                    color: clearAllArea.containsMouse ? ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.3) : ColorUtils.transparentize(MatugenColors.md3.surface_container_high, 0.55)
                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                    Text {
                        id: clearAllLbl
                        anchors.centerIn: parent
                        text: Localization.t("dashboard.notifications.actions.clearAll", "Clear all")
                        font.pixelSize: 13
                        color: MatugenColors.md3.on_surface
                        opacity: 0.65
                    }
                    MouseArea {
                        id: clearAllArea
                        anchors.fill: parent
                        enabled: clearAllWrapper.hasNotifications
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.markListSettling();
                            root.win.requestDismissNotifications(Object.values(NotificationsService.allNotifications));
                            root.win.tabHintMode = false;
                        }
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.bottomMargin: -4
                    width: 14
                    height: 14
                    radius: 3
                    z: 10
                    color: MatugenColors.md3.primary
                    opacity: parent.hasNotifications && root.win.notifHintMode ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "C"
                        font.pixelSize: 8
                        font.bold: true
                        color: MatugenColors.md3.on_primary
                    }
                }
            }

            Item {
                implicitWidth: dndPill.implicitWidth
                implicitHeight: dndPill.implicitHeight
                Rectangle {
                    id: dndPill
                    implicitWidth: dndRow.implicitWidth + 16
                    implicitHeight: 24
                    radius: 5
                    color: NotificationsService.dnd ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.45) : dndMouse.containsMouse ? MatugenColors.md3.surface_container_highest : MatugenColors.md3.surface_container
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    RowLayout {
                        id: dndRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13
                            font.variableAxes: ({
                                    "FILL": 1
                                })
                            renderType: Text.NativeRendering
                            color: MatugenColors.md3.on_surface
                            opacity: NotificationsService.dnd ? 1.0 : 0.55
                            text: "notifications_off"
                        }
                        Text {
                            text: Localization.t("dashboard.notifications.actions.dnd", "DND")
                            font.pixelSize: 14
                            color: MatugenColors.md3.on_surface
                            opacity: NotificationsService.dnd ? 0.9 : 0.55
                        }
                    }
                    MouseArea {
                        id: dndMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationsService.toggleDnd()
                            root.win.tabHintMode = false
                        }
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.bottomMargin: -4
                    width: 14
                    height: 14
                    radius: 3
                    z: 1
                    color: MatugenColors.md3.primary
                    opacity: root.win.notifHintMode ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "D"
                        font.pixelSize: 8
                        font.bold: true
                        color: MatugenColors.md3.on_primary
                    }
                }
            }
        }

        Flickable {
            id: tab1Flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: notifListCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: notifListCol
                width: parent.width
                spacing: 6

                move: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Repeater {
                    id: notifRepeater
                    model: root.win.notifItems
                    delegate: NotifItem {
                        required property var modelData
                        required property int index
                        notif: modelData
                        itemIndex: index
                    }
                }

                Item {
                    implicitHeight: 4
                }
            }

            Item {
                width: tab1Flickable.width
                height: tab1Flickable.height
                y: tab1Flickable.contentY
                z: 20
                visible: root.win.notifItems.length === 0 || opacity > 0.01
                opacity: root.win.notifItems.length === 0 ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: Localization.t("dashboard.notifications.empty", "No notifications")
                    font.pixelSize: 15
                    color: MatugenColors.md3.on_surface
                    opacity: 0.28
                }
            }
        }
    }
}
