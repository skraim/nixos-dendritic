pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    // Empty string means default submap; non-empty is the active submap name.
    // Map to "default" so existing consumers using !== "default" keep working.
    readonly property string submap: HyprlandData.submap !== "" ? HyprlandData.submap : "default"
}
