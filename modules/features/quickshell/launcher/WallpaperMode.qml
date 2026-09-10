import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property int listHeight: targetListHeight
    readonly property int targetListHeight: 260
    readonly property bool isCalcMode: false
    readonly property bool readyToShow: wallpaperPreload.ready
    property bool isDarkTheme: true
    property string wallpapersDir: Settings.wallpapersPath.replace("~", Quickshell.env("HOME"))
    property var wallpapers: []
    property bool wallpapersLoaded: false

    spacing: 8

    function activate() {
        wallpaperSearchInput.text = "";
        wallpaperList.resetting = true;
        selectActiveWallpaper();
        wallpaperPreload.prepare();
        resetDoneTimer.restart();
        wallpaperSearchInput.forceActiveFocus();
        isDarkTheme = true;
    }

    function selectActiveWallpaper() {
        const active = WallpaperSwitcherService.activeWallpaper;
        const list = filteredWallpapers;
        const idx = active ? list.indexOf(active) : -1;
        wallpaperList.currentIndex = idx >= 0 ? idx : 0;
    }

    function applyWallpaper(path) {
        const cmd = (isDarkTheme ? Settings.wallpaperCmdDark : Settings.wallpaperCmdLight).replace(/\$@/g, JSON.stringify(path));
        WallpaperSwitcherService.setActiveWallpaper(path);
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    property var filteredWallpapers: {
        const q = wallpaperSearchInput.text.trim().toLowerCase();
        const list = q.length === 0 ? root.wallpapers : root.wallpapers.filter(p => {
            const name = p.split("/").pop().toLowerCase();
            return name.includes(q);
        });
        const active = WallpaperSwitcherService.activeWallpaper;
        if (!active)
            return list;

        const idx = list.indexOf(active);
        if (idx <= 0)
            return list;

        const reordered = [...list];
        reordered.splice(idx, 1);
        reordered.unshift(active);
        return reordered;
    }

    onWallpapersChanged: {
        if (wallpaperSearchInput.text.length === 0) {
            selectActiveWallpaper();
            wallpaperPreload.prepare();
        }
    }

    Connections {
        target: WallpaperSwitcherService
        function onActiveWallpaperChanged() {
            if (wallpaperSearchInput.text.length === 0)
                root.selectActiveWallpaper();
        }
    }

    Process {
        id: wallpaperLoader
        running: true
        command: ["sh", "-c", "find " + JSON.stringify(root.wallpapersDir) + " -maxdepth 1 \\( -type f -o -type l \\)" + " -a \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\)" + " 2>/dev/null | sort"]
        onExited: root.wallpapersLoaded = true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.length > 0) {
                    const w = [...root.wallpapers];
                    w.push(line);
                    root.wallpapers = w;
                }
            }
        }
    }

    Item {
        id: wallpaperPreload
        visible: false
        width: 1
        height: 1

        property int generation: 0
        property int completed: 0
        property var completedKeys: ({})
        property bool revealDelayDone: false
        property var sources: []
        readonly property int expected: sources.length
        readonly property bool ready: root.wallpapersLoaded && revealDelayDone && completed >= expected

        function reset(delay) {
            generation++;
            completed = 0;
            completedKeys = {};
            revealDelayDone = !delay;
            if (delay)
                revealDelay.restart();
        }

        function visibleSources() {
            const list = root.filteredWallpapers;
            const count = list.length;
            if (count === 0)
                return [];

            const center = Math.max(0, Math.min(wallpaperList.currentIndex, count - 1));
            const preloadCount = Math.max(1, Math.min(count, wallpaperList.visiblePathItems));
            const seen = {};
            const picked = [];

            function addOffset(offset) {
                const path = list[(center + offset + count) % count];
                if (seen[path])
                    return;

                seen[path] = true;
                picked.push(path);
            }

            addOffset(0);
            for (let distance = 1; picked.length < preloadCount && distance < count; distance++) {
                addOffset(-distance);
                if (picked.length < preloadCount)
                    addOffset(distance);
            }

            return picked;
        }

        function prepare() {
            sources = [];
            reset(true);
            Qt.callLater(function() {
                wallpaperPreload.sources = wallpaperPreload.visibleSources();
            });
        }

        Timer {
            id: revealDelay
            interval: 120
            repeat: false
            onTriggered: wallpaperPreload.revealDelayDone = true
        }

        function markDone(key) {
            if (completedKeys[key])
                return;

            const next = Object.assign({}, completedKeys);
            next[key] = true;
            completedKeys = next;
            completed++;
        }

        Repeater {
            model: wallpaperPreload.sources

            Image {
                required property string modelData
                required property int index
                readonly property int preloadGeneration: wallpaperPreload.generation
                readonly property string originalPath: modelData
                readonly property string thumbnailPath: WallpaperSwitcherService.thumbnailFor(originalPath)
                property bool triedOriginal: thumbnailPath === originalPath
                property bool markedDone: false

                visible: false
                asynchronous: true
                cache: true
                sourceSize: Qt.size(wallpaperList.itemW, root.listHeight)
                source: "file://" + (triedOriginal ? originalPath : thumbnailPath)

                function complete() {
                    if (markedDone || preloadGeneration !== wallpaperPreload.generation)
                        return;

                    markedDone = true;
                    wallpaperPreload.markDone(preloadGeneration + ":" + index + ":" + originalPath);
                }

                onStatusChanged: {
                    if (status === Image.Ready) {
                        complete();
                    } else if (status === Image.Error) {
                        if (!triedOriginal)
                            triedOriginal = true;
                        else
                            complete();
                    }
                }

                Component.onCompleted: {
                    if (status === Image.Ready) {
                        complete();
                    } else if (status === Image.Error) {
                        if (!triedOriginal)
                            triedOriginal = true;
                        else
                            complete();
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44
        color: MatugenColors.md3.surface_container
        radius: Globals.componentRadius

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 10

            Text {
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                font.variableAxes: ({
                    "FILL": 1
                })
                renderType: Text.NativeRendering
                color: MatugenColors.md3.on_surface
                opacity: 0.6
                text: "\ue8b6"
            }

            TextInput {
                id: wallpaperSearchInput
                Layout.fillWidth: true
                font.pixelSize: 16
                color: MatugenColors.md3.on_surface
                selectionColor: MatugenColors.md3.primary
                clip: true
                onTextChanged: wallpaperList.currentIndex = 0

                Text {
                    anchors.fill: parent
                    text: Localization.t("launcher.placeholders.filterWallpapers", "Filter wallpapers...")
                    font: wallpaperSearchInput.font
                    color: MatugenColors.md3.on_surface
                    opacity: 0.3
                    visible: wallpaperSearchInput.text.length === 0
                    verticalAlignment: Text.AlignVCenter
                }

                Keys.onEscapePressed: WallpaperSwitcherService.dismiss()
                Keys.onReturnPressed: {
                    const path = root.filteredWallpapers[wallpaperList.currentIndex];
                    if (path) {
                        root.applyWallpaper(path);
                        WallpaperSwitcherService.dismiss();
                    }
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Tab) {
                        root.isDarkTheme = !root.isDarkTheme;
                        event.accepted = true;
                    } else if (event.modifiers & Qt.ControlModifier) {
                        const c = wallpaperList.count;
                        if (event.key === Qt.Key_N) {
                            if (event.isAutoRepeat) {
                                wallpaperList.holdNav = true;
                                holdNavTimer.dir = 1;
                                if (!holdNavTimer.running)
                                    holdNavTimer.start();
                                holdEndTimer.restart();
                            } else {
                                wallpaperList.currentIndex = (wallpaperList.currentIndex + 1) % c;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_P) {
                            if (event.isAutoRepeat) {
                                wallpaperList.holdNav = true;
                                holdNavTimer.dir = -1;
                                if (!holdNavTimer.running)
                                    holdNavTimer.start();
                                holdEndTimer.restart();
                            } else {
                                wallpaperList.currentIndex = (wallpaperList.currentIndex - 1 + c) % c;
                            }
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Left) {
                        if (event.isAutoRepeat) {
                            wallpaperList.holdNav = true;
                            holdNavTimer.dir = -1;
                            if (!holdNavTimer.running)
                                holdNavTimer.start();
                            holdEndTimer.restart();
                        } else {
                            const c = wallpaperList.count;
                            wallpaperList.currentIndex = (wallpaperList.currentIndex - 1 + c) % c;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right) {
                        if (event.isAutoRepeat) {
                            wallpaperList.holdNav = true;
                            holdNavTimer.dir = 1;
                            if (!holdNavTimer.running)
                                holdNavTimer.start();
                            holdEndTimer.restart();
                        } else {
                            wallpaperList.currentIndex = (wallpaperList.currentIndex + 1) % wallpaperList.count;
                        }
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                implicitHeight: 30
                implicitWidth: themeToggleRow.implicitWidth + 6
                radius: Globals.componentRadius - 4
                color: MatugenColors.md3.surface_container_low

                RowLayout {
                    id: themeToggleRow
                    anchors.centerIn: parent
                    spacing: 2

                    Rectangle {
                        implicitWidth: darkLbl.implicitWidth + 20
                        implicitHeight: 24
                        radius: Globals.componentRadius - 6
                        color: root.isDarkTheme ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Text {
                            id: darkLbl
                            anchors.centerIn: parent
                            text: Localization.t("launcher.theme.dark", "Dark")
                            font.pixelSize: 13
                            color: MatugenColors.md3.on_surface
                            opacity: root.isDarkTheme ? 1.0 : 0.45
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isDarkTheme = true
                        }
                    }

                    Rectangle {
                        implicitWidth: lightLbl.implicitWidth + 20
                        implicitHeight: 24
                        radius: Globals.componentRadius - 6
                        color: !root.isDarkTheme ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.4) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Text {
                            id: lightLbl
                            anchors.centerIn: parent
                            text: Localization.t("launcher.theme.light", "Light")
                            font.pixelSize: 13
                            color: MatugenColors.md3.on_surface
                            opacity: !root.isDarkTheme ? 1.0 : 0.45
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isDarkTheme = false
                        }
                    }
                }
            }
        }
    }

    Item {
        id: listArea
        Layout.fillWidth: true
        implicitHeight: root.listHeight
        clip: true

        PathView {
            id: wallpaperList
            anchors.fill: parent
            clip: true
            model: root.filteredWallpapers

            readonly property int itemW: Math.floor((width - 3 * 8) / 4)
            readonly property int itemStep: itemW + 8
            readonly property int visiblePathItems: Math.min(Math.max(count, 1), Math.round(width / itemStep) + 3)

            pathItemCount: visiblePathItems
            cacheItemCount: 2
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            property bool holdNav: false
            property bool resetting: false
            highlightMoveDuration: resetting ? 0 : (holdNav ? 70 : 200)

            Timer {
                id: resetDoneTimer
                interval: 50
                onTriggered: wallpaperList.resetting = false
            }

            Timer {
                id: holdNavTimer
                interval: 85
                repeat: true
                property int dir: 0
                onTriggered: {
                    const c = wallpaperList.count;
                    wallpaperList.currentIndex = (wallpaperList.currentIndex + dir + c) % c;
                }
            }

            Timer {
                id: holdEndTimer
                interval: 150
                onTriggered: {
                    holdNavTimer.stop();
                    wallpaperList.holdNav = false;
                }
            }

            path: Path {
                startX: wallpaperList.width / 2 - wallpaperList.visiblePathItems * wallpaperList.itemStep / 2
                startY: wallpaperList.height / 2
                PathLine {
                    x: wallpaperList.width / 2 + wallpaperList.visiblePathItems * wallpaperList.itemStep / 2
                    y: wallpaperList.height / 2
                }
            }

            Keys.onReturnPressed: {
                const path = root.filteredWallpapers[currentIndex];
                if (path) {
                    root.applyWallpaper(path);
                    WallpaperSwitcherService.dismiss();
                }
            }

            delegate: Item {
                id: wpDelegate
                required property var modelData
                required property int index
                property bool thumbnailFailed: false
                readonly property string cachedThumbnail: WallpaperSwitcherService.thumbnailFor(modelData)
                readonly property string previewPath: thumbnailFailed ? modelData : cachedThumbnail
                width: wallpaperList.itemW
                height: listArea.height

                onCachedThumbnailChanged: thumbnailFailed = false

                Rectangle {
                    anchors {
                        fill: parent
                        margins: 4
                    }
                    radius: Globals.componentRadius - 2
                    color: wpDelegate.PathView.isCurrentItem ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.3) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                        }
                    }
                    scale: wpDelegate.PathView.isCurrentItem ? 1.0 : 0.91
                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: wpThumbMask
                        anchors {
                            fill: parent
                            margins: 3
                        }
                        radius: Globals.componentRadius - 5
                        visible: false
                        layer.enabled: true
                    }

                    Rectangle {
                        anchors {
                            fill: parent
                            margins: 3
                        }
                        radius: Globals.componentRadius - 5
                        color: MatugenColors.md3.surface_variant
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: wpThumbMask
                        }

                        Image {
                            anchors.fill: parent
                            source: "file://" + wpDelegate.previewPath
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            asynchronous: true
                            sourceSize: Qt.size(wallpaperList.itemW, listArea.height)
                            onStatusChanged: {
                                if (status === Image.Error && !wpDelegate.thumbnailFailed && wpDelegate.cachedThumbnail !== modelData)
                                    wpDelegate.thumbnailFailed = true;
                            }
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: 40
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop {
                                    position: 0.0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: ColorUtils.transparentize(MatugenColors.md3.shadow, 0.25)
                                }
                            }

                            Text {
                                anchors {
                                    bottom: parent.bottom
                                    bottomMargin: 5
                                    left: parent.left
                                    right: parent.right
                                    leftMargin: 7
                                    rightMargin: 7
                                }
                                text: modelData.split("/").pop().replace(/\.[^.]+$/, "")
                                font.pixelSize: 11
                                color: "white"
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (!wallpaperList.moving)
                                wallpaperList.currentIndex = index;
                        }
                        onClicked: {
                            root.applyWallpaper(modelData);
                            WallpaperSwitcherService.dismiss();
                        }
                    }
                }
            }
        }
    }
}
