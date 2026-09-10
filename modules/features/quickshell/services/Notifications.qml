pragma Singleton
pragma ComponentBehavior: Bound

import qs.utils
import QtQuick
import Quickshell

Singleton {
    id: root

    property string icon: Icons.getNotificationIcon(NotificationsService.dnd ? "dnd" : "default")
    property int count: {
        NotificationsService.updateCounter  // reactive dependency
        return Object.keys(NotificationsService.allNotifications).length
    }

    function toggleDnd() {
        NotificationsService.toggleDnd();
    }
}
