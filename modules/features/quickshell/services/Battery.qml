pragma Singleton

import Quickshell
import Quickshell.Services.UPower

Singleton {
    property bool available: UPower.displayDevice.isLaptopBattery
    property var chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice.percentage
    property bool isLow: percentage <= .15
    property bool isCritical: percentage <= .1
    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging

    onIsLowAndNotChargingChanged: {
        if (available && isLowAndNotCharging)
            Quickshell.execDetached(["notify-send", Localization.t("notifications.battery.low.title", "Low battery"), Localization.t("notifications.battery.low.body", "Consider plugging in your device"), "-u", "critical", "-a", "Shell"]);
    }

    onIsCriticalAndNotChargingChanged: {
        if (available && isCriticalAndNotCharging)
            Quickshell.execDetached(["notify-send", Localization.t("notifications.battery.critical.title", "Critically low battery"), Localization.t("notifications.battery.critical.body", "Please charge!"), "-u", "critical", "-a", "Shell"]);
    }
}
