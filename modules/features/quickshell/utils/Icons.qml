pragma Singleton

import qs.services
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

Singleton {
    readonly property var nix: ({
            "icon": "󱄅",
            "color": MatugenColors.md3.tertiary
        })

    readonly property var notificationIcons: ({
            "default": "notifications",
            "dnd": "notifications_paused"
        })

    readonly property var kbLayoutIcons: ({
            "Ukrainian": "🇺🇦Q",
            "Ukrainian (Graphite reverse)": "🇺🇦",
            "English (US)": "🇬🇧"
        })

    function getKbLayoutIcon(language: string): string {
        if (kbLayoutIcons.hasOwnProperty(language))
            return kbLayoutIcons[language];
        return "❔";
    }

    function getBluetoothIcon(icon: string): string {
        if (icon.includes("headset") || icon.includes("headphones"))
            return "headphones";
        if (icon.includes("audio"))
            return "speaker";
        if (icon.includes("phone"))
            return "smartphone";
        if (icon.includes("mouse"))
            return "mouse";
        if (icon.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    function getNotificationIcon(icon: string): string {
        if (notificationIcons.hasOwnProperty(icon))
            return notificationIcons[icon];
        return "notifications";
    }

    function getBatteryStateIcon(state: var): string {
        if (state == UPowerDeviceState.Charging)
            return "bolt";
        if (state == UPowerDeviceState.Charging)
            return "power";
        return "";
    }

    function getBatteryIcon(percentage: real): string {
        if (percentage <= 0.1)
            return "battery_0_bar";
        if (percentage <= 0.2)
            return "battery_1_bar";
        if (percentage <= 0.3)
            return "battery_2_bar";
        if (percentage <= 0.5)
            return "battery_3_bar";
        if (percentage <= 0.7)
            return "battery_4_bar";
        if (percentage <= 0.8)
            return "battery_5_bar";
        if (percentage <= 0.9)
            return "battery_6_bar";
        return "battery_full";
    }

    function getAudioSinkIcon(isBluetooth: bool, node: PwNode): string {
        if (isBluetooth) {
            return node?.audio?.muted ? "headset_off" : "headset_mic";
        }

        if (node?.audio?.muted)
            return "volume_off";
        if (node?.audio?.volume > .5)
            return "volume_up";
        if (node?.audio?.volume <= .5)
            return "volume_down";
        return "";
    }

    function getNetworkIcon(): string {
        return Network.ethernet
            ? "lan"
            : Network.wifi
                ? (Network.networkStrength > 80
                    ? "signal_wifi_4_bar"
                    : Network.networkStrength > 60
                        ? "network_wifi_3_bar"
                        : Network.networkStrength > 40
                            ? "network_wifi_2_bar"
                            : Network.networkStrength > 20
                                ? "network_wifi_1_bar"
                                : "signal_wifi_0_bar")
                : "signal_wifi_off";
    }
}
