//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar
import qs.bar.widgets
import qs.overlay
import qs.launcher
import qs.pickers
import qs.whichkey
import qs.powermenu
import qs.dashboard

Scope {
    Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.cache/quickshell"]
        running: true
    }

    Bar {}
    SubmapWidget {}
    Overlays {}
    Launcher {}
    Pickers {}
    WhichKey {}
    PowerMenu {}
    Dashboard {}
}
