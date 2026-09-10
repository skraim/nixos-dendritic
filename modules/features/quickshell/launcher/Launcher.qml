import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
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

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            visible: launcherWindow.visible

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: launcherWindow.isOpen && launcherWindow.wallpaperReadyToShow ? 0.5 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: launcherWindow.wallpaperReadyToShow
                onClicked: launcherWindow.dismissCurrent()
            }
        }
    }

    PanelWindow {
        id: launcherWindow

        property string mode: "app"
        readonly property bool isAppMode: mode === "app"
        readonly property bool isRunMode: mode === "run"
        readonly property bool isWallpaperMode: mode === "wallpaper"

        property string displayMode: "app"
        property bool isOpen: false
        property bool anyVisible: AppLauncherService.visible || RunLauncherService.visible || WallpaperSwitcherService.visible
        property int animatedListHeight: modeTargetHeight(displayMode)

        readonly property bool wallpaperGateActive: WallpaperSwitcherService.visible || mode === "wallpaper" || displayMode === "wallpaper"
        readonly property bool wallpaperReadyToShow: !wallpaperGateActive || (displayMode === "wallpaper" && modeLoader.item && modeLoader.item.readyToShow)

        visible: isOpen || closeTimer.running
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        function modeTargetHeight(value) {
            return value === "wallpaper" ? 260 : 10 * 46;
        }

        function updateMode() {
            if (RunLauncherService.visible)
                mode = "run";
            else if (WallpaperSwitcherService.visible)
                mode = "wallpaper";
            else if (AppLauncherService.visible)
                mode = "app";
        }

        function dismissCurrent() {
            if (isAppMode)
                AppLauncherService.dismiss();
            else if (isRunMode)
                RunLauncherService.dismiss();
            else
                WallpaperSwitcherService.dismiss();
        }

        function activateCurrentMode() {
            if (modeLoader.item && modeLoader.item.activate)
                modeLoader.item.activate();
        }

        onAnyVisibleChanged: {
            if (anyVisible) {
                closeTimer.stop();
                updateMode();
                isOpen = true;
            } else {
                listCollapse.stop();
                listExpand.stop();
                closeTimer.restart();
                isOpen = false;
            }
        }

        Connections {
            target: AppLauncherService
            function onVisibleChanged() {
                if (launcherWindow.anyVisible)
                    launcherWindow.updateMode();
            }
        }
        Connections {
            target: RunLauncherService
            function onVisibleChanged() {
                if (launcherWindow.anyVisible)
                    launcherWindow.updateMode();
            }
        }
        Connections {
            target: WallpaperSwitcherService
            function onVisibleChanged() {
                if (launcherWindow.anyVisible)
                    launcherWindow.updateMode();
            }
        }

        Timer {
            id: closeTimer
            interval: 300
            repeat: false
        }

        NumberAnimation {
            id: listCollapse
            target: launcherWindow
            property: "animatedListHeight"
            to: 0
            duration: 180
            easing.type: Easing.InCubic
            onFinished: {
                launcherWindow.displayMode = launcherWindow.mode;
                launcherWindow.animatedListHeight = 0;
                listExpand.to = launcherWindow.modeTargetHeight(launcherWindow.displayMode);
                listExpand.start();
            }
        }

        NumberAnimation {
            id: listExpand
            target: launcherWindow
            property: "animatedListHeight"
            duration: 200
            easing.type: Easing.OutCubic
        }

        onIsOpenChanged: {
            if (isOpen) {
                displayMode = mode;
                animatedListHeight = modeTargetHeight(displayMode);
                activateCurrentMode();
            }
        }

        onModeChanged: {
            if (isOpen && anyVisible) {
                listExpand.stop();
                listCollapse.from = animatedListHeight;
                listCollapse.start();
            } else if (anyVisible) {
                displayMode = mode;
                animatedListHeight = modeTargetHeight(displayMode);
            }
        }

        onDisplayModeChanged: {
            if (isOpen)
                Qt.callLater(function() {
                    launcherWindow.activateCurrentMode();
                });
        }

        Keys.onEscapePressed: dismissCurrent()

        MouseArea {
            anchors.fill: parent
            enabled: launcherWindow.isOpen && launcherWindow.wallpaperReadyToShow
            onClicked: launcherWindow.dismissCurrent()
        }

        Item {
            id: panelRoot

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: launcherWindow.wallpaperReadyToShow ? 1 : 0
            enabled: launcherWindow.wallpaperReadyToShow
            Behavior on opacity {
                enabled: launcherWindow.wallpaperReadyToShow
                NumberAnimation {
                    duration: 90
                    easing.type: Easing.OutCubic
                }
            }

            width: (launcherWindow.isWallpaperMode ? 1400 : 820) + 2 * Globals.componentRadius
            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            height: mainRect.height

            transform: Translate {
                y: launcherWindow.isOpen && launcherWindow.wallpaperReadyToShow ? 0 : panelRoot.height
                Behavior on y {
                    enabled: launcherWindow.wallpaperReadyToShow
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                radius: 9
                samples: 17
                color: MatugenColors.md3.shadow
            }

            Rectangle {
                id: mainRect
                anchors {
                    top: parent.top
                    left: parent.left
                    leftMargin: Globals.componentRadius
                    right: parent.right
                    rightMargin: Globals.componentRadius
                }
                height: panelContent.implicitHeight + 24
                color: MatugenColors.md3.surface
                topLeftRadius: Globals.componentRadius
                topRightRadius: Globals.componentRadius
                clip: true

                ColumnLayout {
                    id: panelContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 12
                    }
                    spacing: 8

                    Loader {
                        id: modeLoader
                        Layout.fillWidth: true
                        sourceComponent: launcherWindow.displayMode === "wallpaper" ? wallpaperModeComponent : (launcherWindow.displayMode === "run" ? runModeComponent : appModeComponent)
                    }
                }
            }

            Shape {
                x: 0
                y: mainRect.height
                width: Globals.componentRadius
                height: Globals.componentRadius
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillColor: MatugenColors.md3.surface
                    startX: Globals.componentRadius
                    startY: 0
                    PathLine {
                        relativeX: -Globals.componentRadius
                        relativeY: 0
                    }
                    PathArc {
                        relativeX: Globals.componentRadius
                        relativeY: -Globals.componentRadius
                        radiusX: Globals.componentRadius
                        radiusY: Globals.componentRadius
                        direction: PathArc.Counterclockwise
                    }
                }
            }

            Shape {
                x: panelRoot.width - Globals.componentRadius
                y: mainRect.height
                width: Globals.componentRadius
                height: Globals.componentRadius
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillColor: MatugenColors.md3.surface
                    startX: 0
                    startY: 0
                    PathLine {
                        relativeX: Globals.componentRadius
                        relativeY: 0
                    }
                    PathArc {
                        relativeX: -Globals.componentRadius
                        relativeY: -Globals.componentRadius
                        radiusX: Globals.componentRadius
                        radiusY: Globals.componentRadius
                        direction: PathArc.Clockwise
                    }
                }
            }
        }

        Component {
            id: appModeComponent
            AppMode {
                listHeight: launcherWindow.animatedListHeight
            }
        }

        Component {
            id: runModeComponent
            RunMode {
                listHeight: launcherWindow.animatedListHeight
            }
        }

        Component {
            id: wallpaperModeComponent
            WallpaperMode {
                listHeight: launcherWindow.animatedListHeight
            }
        }
    }
}
