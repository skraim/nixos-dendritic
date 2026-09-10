import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.utils

Scope {
    Variants {
        model: {
            const all = Quickshell.screens;
            if (!all || all.length === 0) return [];
            const desc = s => {
                try { return Hyprland.monitorFor(s)?.description ?? ""; }
                catch(e) { return ""; }
            };
            const match = (s, name) => {
                const d = desc(s);
                return d.length > 0 && (d.includes(name) || name.includes(d));
            };
            if (Settings.mainScreen) {
                for (const s of all) {
                    if (match(s, Settings.mainScreen)) return [s];
                }
            }
            for (const name of Settings.screens) {
                for (const s of all) {
                    if (match(s, name)) return [s];
                }
            }
            return [all[0]];
        }

        PanelWindow {
            id: popup_window
            property var modelData
            screen: modelData
            color: "transparent"
        visible: true

        property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(screen)
        property bool dashOnThisScreen: DashboardService.visible && DashboardService.screen != null &&
            Hyprland.monitorFor(DashboardService.screen)?.id === Hyprland.monitorFor(popup_window.screen)?.id
        property bool trayOnThisScreen: BarNavigationService.trayMenuOpen && BarNavigationService.trayMenuScreen === popup_window.screen
        property bool hasFullscreen: HyprlandData.fullscreenOnMonitor(hyprMonitor)
        property bool shifted: dashOnThisScreen || trayOnThisScreen
        property real fullscreenEdgeOffset: hasFullscreen ? -64 : 0
        property real shiftAmount: fullscreenEdgeOffset + (dashOnThisScreen ? 488 : (trayOnThisScreen ? BarNavigationService.trayMenuWidth : 0))
        Behavior on shiftAmount {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        property bool hasNotifications: notification_container.activeNotifications.length > 0
                                        || notification_container.queuedNotifications.length > 0

        property real targetBottomMargin: hasNotifications ? 12 : -450

        anchors {
            bottom: true
            left: true
        }

        margins {
            bottom: targetBottomMargin
            left: shiftAmount
        }

        width: 407
        height: 450

        WlrLayershell.layer: WlrLayer.Overlay

        // Container for manually managed notifications
        Item {
            id: notification_container
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: implicitHeight
            clip: false

            property bool isRemoving: false
            Behavior on height {
                enabled: notification_container.isRemoving
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            readonly property int maxVisible: {
                const screenDesc = Hyprland.monitorFor(popup_window.modelData)?.description ?? "";
                for (const key of Object.keys(Settings.maxNotifications)) {
                    if (screenDesc.includes(key) || key.includes(screenDesc)) {
                        return Settings.maxNotifications[key];
                    }
                }
                return 3;
            }
            property var activeNotifications: []
            property var queuedNotifications: []

            // Component definition for creating notifications
            property Component notificationComponent: NotificationPopup {
                width: notification_container.width - 10
                shifted: popup_window.shifted

                onReadyToDestroy: {
                    notification_container.removeNotification(this);
                }
            }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                radius: 9
                samples: 17
                color: MatugenColors.md3.shadow
            }

            // Calculate height based on active notifications
            implicitHeight: {
                const n = activeNotifications.length;
                let totalHeight = 0;
                for (let i = 0; i < n; i++) {
                    if (activeNotifications[i]) {
                        totalHeight += activeNotifications[i].height;
                    }
                }
                // Remove the overlapping corner space between adjacent notifications
                if (n > 1)
                    totalHeight -= (n - 1) * 2 * Globals.componentRadius;
                return totalHeight;
            }

            onImplicitHeightChanged: updatePositions()

            function addNotification(notificationData) {
                notificationData.timerPaused = false;
                const component = notificationComponent.createObject(notification_container, {
                    notification: notificationData,
                    x: 0,
                    y: 0
                });
                if (component) {
                    activeNotifications = [...activeNotifications, component];
                }
            }

            function removeNotification(component) {
                isRemoving = true;
                activeNotifications = activeNotifications.filter(n => n !== component);
                Qt.callLater(function() {
                    component.destroy();
                    isRemoving = false;
                    if (queuedNotifications.length > 0 && dequeueTimer.pending === null && !dequeueTimer.running) {
                        const next = queuedNotifications[0];
                        queuedNotifications = queuedNotifications.slice(1);
                        dequeueTimer.pending = next;
                        dequeueTimer.start();
                    }
                });
            }

            Timer {
                id: dequeueTimer
                property var pending: null
                interval: 250  // wait for stack settle animation (200ms) to finish
                repeat: false
                onTriggered: {
                    if (pending) {
                        const toShow = [pending];
                        pending = null;
                        const slots = notification_container.maxVisible - notification_container.activeNotifications.length - 1;
                        for (let i = 0; i < slots && notification_container.queuedNotifications.length > 0; i++) {
                            toShow.push(notification_container.queuedNotifications[0]);
                            notification_container.queuedNotifications = notification_container.queuedNotifications.slice(1);
                        }
                        for (const notif of toShow) {
                            notification_container.addNotification(notif);
                        }
                    }
                }
            }

            function updatePositions() {
                let currentY = 0;
                for (let i = activeNotifications.length - 1; i >= 0; i--) {
                    const notif = activeNotifications[i];
                    if (!notif)
                        continue;
                    notif.x = 0;
                    notif.y = currentY;
                    currentY += notif.height - 2 * Globals.componentRadius;
                }
            }

            Connections {
                target: NotificationsService
                function onPopupsChanged() {
                    notification_container.syncNotifications();
                }
            }

            function syncNotifications() {
                const popups = NotificationsService.popups || [];

                for (const popup of popups) {
                    const inActive  = activeNotifications.some(n => n && n.notification === popup);
                    const inQueue   = queuedNotifications.includes(popup);
                    const inPending = dequeueTimer.pending === popup;
                    if (!inActive && !inQueue && !inPending) {
                        if (activeNotifications.length < maxVisible)
                            addNotification(popup);
                        else {
                            popup.timerPaused = true;
                            queuedNotifications = [...queuedNotifications, popup];
                        }
                    }
                }

                // Drop queued items that are no longer in the service
                queuedNotifications.filter(n => !popups.includes(n)).forEach(n => { n.timerPaused = false; });
                queuedNotifications = queuedNotifications.filter(n => popups.includes(n));

                const toRemove = activeNotifications.filter(n => n && !popups.includes(n.notification));
                for (const component of toRemove)
                    component.closeWithAnimation();
            }

            // Initial sync
            Component.onCompleted: {
                syncNotifications();
            }
        }
        }
    }
}
