pragma Singleton

import Quickshell

Singleton {
    id: root

    function dismissAll() {
        AppLauncherService.dismiss()
        RunLauncherService.dismiss()
        ClipHistService.dismiss()
        DashboardService.dismiss()
        WhichKeyService.dismiss()
        PassMenuService.dismiss()
        BluetoothPickerService.dismiss()
        VMPickerService.dismiss()
        VPNPickerService.dismiss()
        AudioOutputPickerService.dismiss()
        EjectPickerService.dismiss()
        PassGenerateService.dismiss()
        WallpaperSwitcherService.dismiss()
    }

    function dismissAllExceptDashboard() {
        AppLauncherService.dismiss()
        RunLauncherService.dismiss()
        ClipHistService.dismiss()
        WhichKeyService.dismiss()
        PassMenuService.dismiss()
        BluetoothPickerService.dismiss()
        VMPickerService.dismiss()
        VPNPickerService.dismiss()
        AudioOutputPickerService.dismiss()
        EjectPickerService.dismiss()
        PassGenerateService.dismiss()
        WallpaperSwitcherService.dismiss()
    }
}
