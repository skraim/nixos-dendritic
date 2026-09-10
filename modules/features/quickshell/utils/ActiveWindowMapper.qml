pragma Singleton

import Quickshell

Singleton {
    readonly property var appNames: ({
            "org.telegram.desktop": "Telegram",
            "org.pulseaudio.pavucontrol": "PulseAudio Control",
            "jetbrains-idea-ce": "IntelliJ IDEA"
        })

    function getAppName(originalName: string): string {
        if (appNames.hasOwnProperty(originalName))
            return appNames[originalName];
        return originalName;
    }
}
