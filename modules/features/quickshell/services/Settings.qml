pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var supportedLanguages: ["en", "ua"]
    property string language:           "en"
    property string terminal:           "kitty"
    property var    vpns:               []
    property string disconnectVpnsPath: ""
    property string defaultAudioSink:   ""
    property string customScriptsPath:  "~/scripts"
    property string cachePath:          "~/.cache/quickshell"
    property string wallpapersPath:     "~/Pictures/wallpapers"
    property string activeWallpaperCmd: "awww query -j | jq -r 'first(.[].[]?.displaying.image // empty)'"
    property string wallpaperCmdDark:   "wal --cols16 lighten -i $@ -n -o ~/scripts/post-pywal.sh"
    property string wallpaperCmdLight:  "wal -l -i $@ -n -o ~/scripts/post-pywal.sh"
    property var    screens:            []
    property string mainScreen:         ""
    property var    maxNotifications:   ({})
    property var    powerMenuMonitorColumns: ({})
    property var    notificationCenterIgnoreApps: []
    property var    appIcons:           ({})
    property string distroIcon:         ""
    property int    calendarFirstDayOfWeek: 1
    property var    powerMenuCmds:      ({
        lock: "hyprlock",
        monitorOff: "sleep 0.5 && hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'",
        suspend: "hyprshutdown -t 'Suspending...' --post-cmd systemctl suspend",
        logout: "hyprshutdown -t 'Logging out...'",
        reboot: "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'",
        shutdown: "hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'"
    })

    Process {
        id: settingsReader
        running: true
        command: ["cat", Quickshell.shellDir + "/settings.json"]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => { settingsReader.buffer += data + "\n" }
        }
        onExited: {
            try {
                const s = JSON.parse(settingsReader.buffer)
                root.language           = normalizeLanguage(s.language)
                root.terminal           = s.terminal            || root.terminal
                root.vpns               = s.vpns || []
                root.disconnectVpnsPath = s.disconnect_vpns_path || ""
                root.defaultAudioSink   = s.default_audio_sink || ""
                root.customScriptsPath  = s.custom_scripts_path  || root.customScriptsPath
                root.cachePath          = s.cache_path            || root.cachePath
                root.wallpapersPath     = s.wallpapers_path      || root.wallpapersPath
                root.activeWallpaperCmd = s.active_wallpaper_cmd || root.activeWallpaperCmd
                root.wallpaperCmdDark   = s.wallpaper_cmd_dark   || root.wallpaperCmdDark
                root.wallpaperCmdLight  = s.wallpaper_cmd_light  || root.wallpaperCmdLight
                root.screens            = s.screens              || []
                root.mainScreen         = s.main_screen          || ""
                root.maxNotifications   = s.max_notifications    || {}
                root.powerMenuMonitorColumns = s.power_menu_monitor_columns || s.powermune_monitor_columns || {}
                root.notificationCenterIgnoreApps = s.notification_center_ignore_apps || []
                root.appIcons           = s.app_icons            || {}
                root.distroIcon         = s.distro_icon          || ""
                root.calendarFirstDayOfWeek = Math.max(0, Math.min(6, s.calendar_first_day_of_week ?? root.calendarFirstDayOfWeek))
                root.powerMenuCmds      = s.power_menu_cmds      || root.powerMenuCmds
            } catch(e) {
                console.warn("Settings.qml: failed to parse settings.json:", e)
            }
        }
    }

    function normalizeLanguage(value) {
        const language = String(value || "").toLowerCase()
        return supportedLanguages.indexOf(language) >= 0 ? language : "en"
    }
}
