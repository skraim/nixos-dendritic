pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQml

Singleton {
    id: root

    // IPC handler for CLI control
    IpcHandler {
        target: "notifications"
        enabled: true

        function toggleDnd(): void {
            root.toggleDnd();
        }

        function dismissOldestPopup(): bool {
            return root.dismissOldestPopup();
        }

        function dismissAllPopups(): void {
            root.dismissAllPopups();
        }
    }

    property var trackedNotifications: ({})  // Maps quickshell ID to Notif object
    property var allNotifications: ({})  // Dashboard-visible notifications by quickshell ID
    property var popupsList: []
    property int updateCounter: 0
    property bool dnd: false  // Do Not Disturb mode
    property int totalCount: 0  // Total notifications received (only increases)

    property var popups: {
        updateCounter;  // Force dependency
        return popupsList;
    }

    function toggleDnd() {
        dnd = !dnd;

        if (dnd) {
            // Hide all current popups
            for (let i = 0; i < popupsList.length; i++) {
                if (popupsList[i]) {
                    popupsList[i].popup = false;
                }
            }
        } else {
            // Show only notifications received during DND
            for (const id in trackedNotifications) {
                const notif = trackedNotifications[id];
                if (notif && notif.receivedDuringDnd) {
                    notif.receivedDuringDnd = false;
                    notif.popup = true;
                }
            }
        }
    }

    function appIgnoredByNotificationCenter(notification) {
        const names = Settings.notificationCenterIgnoreApps || [];
        const appName = String(notification?.appName || "").toLowerCase();
        const desktopEntry = String(notification?.desktopEntry || "").toLowerCase();
        const appIcon = String(notification?.appIcon || "").toLowerCase();
        for (const name of names) {
            const needle = String(name || "").toLowerCase();
            if (needle !== "" && (needle === appName || needle === desktopEntry || needle === appIcon))
                return true;
        }
        return false;
    }

    function syncNotificationCenterVisibility(notifObject) {
        const id = notifObject?.notification?.id ?? -1;
        if (id < 0)
            return;
        if (root.appIgnoredByNotificationCenter(notifObject.notification))
            delete root.allNotifications[id];
        else
            root.allNotifications[id] = notifObject;
    }

    function dismissOldestPopup() {
        if (popupsList.length === 0) {
            return false;
        }

        const notif = popupsList[0];
        if (!notif) {
            popupsList.shift();
            popupsList = popupsList.slice();
            updateCounter++;
            return false;
        }

        notif.requestClose = true;
        notif.popup = false;
        return true;
    }

    function dismissAllPopups() {
        if (popupsList.length === 0) {
            return;
        }

        const popupsToDismiss = popupsList.slice();
        popupsList = [];
        updateCounter++;

        for (const notif of popupsToDismiss) {
            if (!notif)
                continue;
            notif.timerPaused = false;
            notif.popup = false;
            notif.requestClose = true;
        }
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true;

            // Check if this is an update to existing notification
            const existingNotif = root.trackedNotifications[notif.id];
            if (existingNotif) {
                // The watcher will handle the update (respects DND mode)
                return;
            }

            const wrappedNotif = notifComp.createObject(root, {
                notification: notif
            });

            if (wrappedNotif) {
                root.trackedNotifications[notif.id] = wrappedNotif;
                root.syncNotificationCenterVisibility(wrappedNotif);
                root.totalCount++;

                if (root.dnd) {
                    wrappedNotif.receivedDuringDnd = true;
                    wrappedNotif.popup = false;
                } else {
                    root.popupsList.push(wrappedNotif);
                    root.popupsList = root.popupsList.slice();
                }
                root.updateCounter++;
            }
        }
    }

    Component {
        id: notificationWatcherComponent
        Connections {
            property var targetNotification
            property var targetNotifObject

            target: targetNotification

            function onSummaryChanged() {
                targetNotifObject.refreshPopup();
            }
            function onBodyChanged() {
                targetNotifObject.refreshPopup();
            }
            function onImageChanged() {
                targetNotifObject.refreshPopup();
            }
            function onAppIconChanged() {
                targetNotifObject.refreshPopup();
            }
            function onUrgencyChanged() {
                root.updateCounter++;
            }
            function onHintsChanged() {
            }
        }
    }

    component Notif: QtObject {
        id: notif

        property bool popup: true
        property bool timerPaused: true   // Paused until notification is actually displayed
        property bool receivedDuringDnd: false
        property bool requestClose: false  // Signal to popup to start close animation
        property bool cancelClose: false   // Signal to cancel any pending close
        property var time: new Date()
        property var _now: new Date()

        readonly property string timeStr: {
            const diff = _now.getTime() - time.getTime();
            const m = Math.floor(diff / 60000);

            if (m < 1)
                return "now";
            if (m < 30)
                return `${m}m ago`;
            const hh = time.getHours().toString().padStart(2, "0");
            const mm = time.getMinutes().toString().padStart(2, "0");
            return `${hh}:${mm}`;
        }

        property Timer _clockTimer: Timer {
            interval: 60000
            running: true
            repeat: true
            onTriggered: {
                notif._now = new Date();
                if (notif._now.getTime() - notif.time.getTime() >= 30 * 60000)
                    running = false;
            }
        }

        required property Notification notification
        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string appIcon: notification.appIcon
        readonly property string appName: notification.appName
        readonly property string image: notification.image
        readonly property int urgency: notification.urgency
        readonly property list<NotificationAction> actions: notification.actions

        property var watcher: notificationWatcherComponent.createObject(root, {
            targetNotification: notification,
            targetNotifObject: notif
        })

        function refreshPopup() {
            notif.cancelClose = true;   // Cancel any pending close animation
            root.syncNotificationCenterVisibility(notif);

            // Only show popup if DND is disabled
            if (!root.dnd) {
                notif.popup = true;
            }

            notif.requestClose = false;  // Reset close request
            notif.time = new Date();
            if (timer) {
                timer.restart();
            }
            root.updateCounter++;
        }

        onPopupChanged: {
            if (!popup) {
                const index = root.popupsList.indexOf(notif);
                if (index !== -1) {
                    root.popupsList.splice(index, 1);
                    root.popupsList = root.popupsList.slice();
                    root.updateCounter++;
                }
            } else {
                // Add back to popups list if not already there
                const index = root.popupsList.indexOf(notif);
                if (index === -1) {
                    root.popupsList.push(notif);
                    root.popupsList = root.popupsList.slice();
                    root.updateCounter++;
                }
            }
        }

        readonly property Timer timer: Timer {
            running: notif.popup && !notif.timerPaused
            interval: {
                const timeout = notif.notification.expireTimeout;
                if (timeout > 0 && timeout < 2147483647) {
                    return timeout;
                }
                return 5000;
            }
            onTriggered: {
                notif.requestClose = true;
            }
        }

        readonly property Connections conn: Connections {
            target: notif.notification.Retainable

            function onDropped(): void {
                removeNotification(notif.notification.id);
            }

            function onAboutToDestroy(): void {
                notif.destroy();
            }
        }
    }

    Component {
        id: notifComp
        Notif {}
    }

    function removeNotification(quickshellId) {
        const notif = root.trackedNotifications[quickshellId];
        if (!notif) {
            return;
        }

        // Remove from popups list
        const index = root.popupsList.indexOf(notif);
        if (index !== -1) {
            root.popupsList.splice(index, 1);
            root.popupsList = root.popupsList.slice();
            root.updateCounter++;
        }

        // Cleanup
        if (notif.watcher) {
            notif.watcher.destroy();
        }
        delete root.trackedNotifications[quickshellId];
        delete root.allNotifications[quickshellId];
        root.updateCounter++;  // always re-evaluate even if notif wasn't in popupsList
    }

}
