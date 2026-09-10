pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool visible: false
    property string mode: ""   // "pass" | "otp"
    property string otpUrl: ""

    function generatePass() {
        PopupManager.dismissAll()
        mode = "pass"
        otpUrl = ""
        visible = true
    }

    function generateOtp(url) {
        if (!url || url.length === 0) return
        PopupManager.dismissAll()
        otpUrl = url
        mode = "otp"
        visible = true
    }

    function execute(key) {
        if (mode === "pass") {
            Quickshell.execDetached(["pass", "generate", "-f", key])
        } else if (mode === "otp") {
            Quickshell.execDetached(["sh", "-c",
                "echo " + JSON.stringify(otpUrl) + " | pass otp insert " + JSON.stringify(key)])
        }
    }

    function dismiss() {
        visible = false
        mode = ""
        otpUrl = ""
    }

    readonly property string _otpFile: "/tmp/qs-otp-url"

    function scanOtp() {
        PassMenuService.dismiss()
        Quickshell.execDetached(["setsid", "sh", "-c",
            `rm -f ${root._otpFile}; grim -g "$(slurp ${Globals.slurpArgs})" - | zbarimg - -q --raw > ${root._otpFile}`])
        otpPoller.attempts = 0
        otpPoller.running = true
    }

    Timer {
        id: otpPoller
        interval: 100
        repeat: true
        running: false
        property int attempts: 0
        onTriggered: {
            attempts++
            if (attempts > 100) {
                running = false
                Quickshell.execDetached(["pkill", "-x", "slurp"])
                Quickshell.execDetached(["notify-send", Localization.t("notifications.passGenerate.otpScanTimedOut.title", "OTP scan timed out"), Localization.t("notifications.passGenerate.otpScanTimedOut.body", "No QR code was captured"), "-u", "normal", "-a", "Shell"])
                return
            }
            otpReader.running = true
        }
    }

    Process {
        id: otpReader
        command: ["cat", root._otpFile]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const url = data.trim()
                if (!url) return
                otpPoller.running = false
                root.generateOtp(url)
                Quickshell.execDetached(["rm", "-f", root._otpFile])
            }
        }
    }
}
