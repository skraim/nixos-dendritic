''
hl.window_rule({
  ["match"] = {
    ["class"] = ".*"
  },
  ["name"] = "suppress-maximize-events",
  ["suppress_event"] = "maximize"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "[lL]ibrewolf"
  },
  ["name"] = "librewolf-workspace",
  ["opacity"] = "1 override",
  ["scrolling_width"] = 0.7,
  ["workspace"] = "1"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "kitty"
  },
  ["name"] = "kitty-workspace",
  ["workspace"] = "2"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "[cC]hromium.*"
  },
  ["name"] = "chromium-workspace",
  ["opacity"] = "1 override",
  ["scrolling_width"] = 0.7,
  ["workspace"] = "3"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "org.telegram.desktop",
    ["initial_title"] = "^Telegram.*$"
  },
  ["name"] = "telegram-workspace",
  ["tag"] = "+chat"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "[sS]lack"
  },
  ["name"] = "slack-workspace",
  ["tag"] = "+chat"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "teams-for-linux"
  },
  ["name"] = "teams-workspace",
  ["opacity"] = "1 override",
  ["scrolling_width"] = 0.7,
  ["workspace"] = "6"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "orca-slicer",
    ["float"] = false
  },
  ["name"] = "orcaslicer-workspace",
  ["tag"] = "+cad"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "org.freecad.FreeCAD",
    ["float"] = false
  },
  ["name"] = "freecad-workspace",
  ["tag"] = "+cad"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "steam"
  },
  ["name"] = "steam-workspace",
  ["opacity"] = "1 override",
  ["workspace"] = "9"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "[sS]potify"
  },
  ["name"] = "spotify-workspace",
  ["workspace"] = "10"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "xdg-desktop-portal-gtk",
    ["initial_title"] = "All Files"
  },
  ["name"] = "portal-file-dialog",
  ["tag"] = "+file-picker"
})
hl.window_rule({
  ["match"] = {
    ["initial_class"] = "[cC]hromium.*",
    ["initial_title"] = "Save File"
  },
  ["name"] = "chromium-save-file",
  ["tag"] = "+file-picker"
})
hl.window_rule({
  ["match"] = {
    ["initial_class"] = "[cC]hromium.*",
    ["initial_title"] = "Open File"
  },
  ["name"] = "chromium-open-file",
  ["tag"] = "+file-picker"
})
hl.window_rule({
  ["match"] = {
    ["initial_class"] = "[cC]hromium.*",
    ["initial_title"] = "Open Files"
  },
  ["name"] = "chromium-open-files",
  ["tag"] = "+file-picker"
})
hl.window_rule({
  ["center"] = true,
  ["float"] = true,
  ["match"] = {
    ["class"] = "org.gnome.Loupe"
  },
  ["name"] = "loupe-float",
  ["size"] = "(monitor_w*0.6) (monitor_h*0.8)"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "org.telegram.desktop",
    ["initial_title"] = "^Telegram.*$"
  },
  ["name"] = "telegram-opacity",
  ["no_screen_share"] = true,
  ["opacity"] = "0.95 override 0.9 override 0.95 override"
})
hl.window_rule({
  ["float"] = true,
  ["fullscreen"] = true,
  ["match"] = {
    ["initial_class"] = "org.telegram.desktop",
    ["initial_title"] = "Media viewer"
  },
  ["name"] = "telegram-media-fs-opacity",
  ["opacity"] = "1 override"
})
hl.window_rule({
  ["float"] = true,
  ["match"] = {
    ["initial_class"] = "org.telegram.desktop",
    ["initial_title"] = "TelegramDesktop"
  },
  ["name"] = "telegram-media-opacity",
  ["opacity"] = "1 override"
})
hl.window_rule({
  ["match"] = {
    ["class"] = ".*",
    ["workspace"] = "8"
  },
  ["name"] = "sharing-ws-opacity",
  ["opacity"] = "1 override"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "thunar"
  },
  ["name"] = "thunar-opacity",
  ["opacity"] = "0.9"
})
hl.window_rule({
  ["center"] = true,
  ["float"] = true,
  ["match"] = {
    ["class"] = "org.pulseaudio.pavucontrol"
  },
  ["name"] = "pavucontrol-float",
  ["opacity"] = "0.85",
  ["size"] = "monitor_w*0.3 monitor_h*0.8"
})
hl.window_rule({
  ["center"] = true,
  ["float"] = true,
  ["match"] = {
    ["class"] = "com.gabm.satty"
  },
  ["name"] = "satty-float"
})
hl.window_rule({
  ["match"] = {
    ["class"] = "[sS]potify"
  },
  ["name"] = "spotify-opacity",
  ["opacity"] = "0.9 override"
})
hl.window_rule({
  ["center"] = true,
  ["float"] = true,
  ["match"] = {
    ["class"] = "thunar",
    ["title"] = "File Operation Progress"
  },
  ["name"] = "thunar-progress-float"
})
hl.window_rule({
  ["float"] = true,
  ["keep_aspect_ratio"] = true,
  ["match"] = {
    ["title"] = "Picture[- ]in[- ]?[Pp]icture"
  },
  ["move"] = "monitor_w-970 monitor_h-550",
  ["name"] = "picture-in-picture",
  ["no_initial_focus"] = true,
  ["pin"] = true,
  ["size"] = "960 540"
})
hl.window_rule({
  ["float"] = true,
  ["match"] = {
    ["class"] = "jetbrains-.*"
  },
  ["name"] = "jetbrains-popups",
  ["no_follow_mouse"] = true,
  ["no_initial_focus"] = true
})
hl.window_rule({
  ["match"] = {
    ["class"] = "steam_app_881100"
  },
  ["name"] = "noita-immediate",
  ["tag"] = "+game"
})
hl.window_rule({
  ["float"] = true,
  ["keep_aspect_ratio"] = true,
  ["match"] = {
    ["class"] = "teams-for-linux",
    ["initial_title"] = ".* Screen is being shared"
  },
  ["move"] = "monitor_w-970 monitor_h-550",
  ["name"] = "teams-windows",
  ["no_initial_focus"] = true,
  ["size"] = "960 540"
})
hl.window_rule({
  ["center"] = true,
  ["float"] = true,
  ["match"] = {
    ["initial_title"] = "Select what to share"
  },
  ["name"] = "sharepicker"
})
hl.window_rule({
  ["match"] = {
    ["tag"] = "chat"
  },
  ["name"] = "chatting-ws",
  ["workspace"] = "4"
})
hl.window_rule({
  ["match"] = {
    ["tag"] = "cad"
  },
  ["name"] = "cad-ws",
  ["opacity"] = "1 override",
  ["scrolling_width"] = 1,
  ["workspace"] = "7"
})
hl.window_rule({
  ["center"] = true,
  ["float"] = true,
  ["match"] = {
    ["tag"] = "file-picker"
  },
  ["name"] = "picker-layout",
  ["size"] = "(monitor_w*0.5) (monitor_h*0.8)"
})
hl.window_rule({
  ["immediate"] = true,
  ["match"] = {
    ["tag"] = "game"
  },
  ["name"] = "game-tearing"
})

-- settings.workspace_rule
hl.workspace_rule({
  ["gaps_in"] = 30,
  ["gaps_out"] = 50,
  ["workspace"] = "s[true]"
})

''
