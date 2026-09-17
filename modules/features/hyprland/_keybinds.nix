''
hl.bind("SUPER + SHIFT + Q", (hl.dsp.exec_cmd("qs ipc call powermenu toggle")))
hl.bind("SUPER + Return", (hl.dsp.exec_cmd("kitty")))
hl.bind("SUPER + B", (hl.dsp.exec_cmd("qs ipc call whichkey toggle browser")))
hl.bind("SUPER + SHIFT + C", (hl.dsp.exec_cmd("qs ipc call whichkey toggle window")))
hl.bind("SUPER + F", (hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })))
hl.bind("SUPER + SHIFT + F", (hl.dsp.window.fullscreen()))
hl.bind("SUPER + P", (hl.dsp.window.pin()))
hl.bind("SUPER + V", (hl.dsp.window.float()))
hl.bind("SUPER + Q", (hl.dsp.exec_cmd("qs ipc call whichkey toggle bar")))
hl.bind("SUPER + Space", (hl.dsp.exec_cmd("qs ipc call launcher toggle; hyprctl switchxkblayout current 0")))
hl.bind("SUPER + SHIFT + Space", (hl.dsp.exec_cmd("qs ipc call run toggle; hyprctl switchxkblayout current 0")))
hl.bind("SUPER + SHIFT + comma", (hl.dsp.workspace.move({ monitor = "+1" })))
hl.bind("SUPER + SHIFT + V", (hl.dsp.exec_cmd("qs ipc call cliphist toggle; hyprctl switchxkblayout current 0")))
hl.bind("SUPER + SHIFT + P", (hl.dsp.exec_cmd("qs ipc call whichkey toggle picker; hyprctl switchxkblayout current 0")))
hl.bind("Print", (hl.dsp.exec_cmd("qs ipc call whichkey toggle screen")))
hl.bind("SUPER + A", (hl.dsp.focus({ direction = "up" })))
hl.bind("SUPER + H", (hl.dsp.focus({ direction = "down" })))
hl.bind("SUPER + Up", (hl.dsp.focus({ direction = "up" })))
hl.bind("SUPER + Down", (hl.dsp.focus({ direction = "down" })))
hl.bind("SUPER + bracketright", (hl.dsp.window.move({ direction = "right" })))
hl.bind("SUPER + bracketleft", (hl.dsp.window.move({ direction = "left" })))
hl.bind("SUPER + SHIFT + A", (hl.dsp.window.move({ direction = "up" })))
hl.bind("SUPER + SHIFT + H", (hl.dsp.window.move({ direction = "down" })))
hl.bind("SUPER + SHIFT + Up", (hl.dsp.window.move({ direction = "up" })))
hl.bind("SUPER + SHIFT + Down", (hl.dsp.window.move({ direction = "down" })))
hl.bind("SUPER + N", (hl.dsp.exec_cmd("qs ipc call notifications dismissOldestPopup")))
hl.bind("SUPER + SHIFT + N", (hl.dsp.exec_cmd("qs ipc call notifications dismissAllPopups")))
hl.bind("SUPER + S", (hl.dsp.workspace.toggle_special("")))
hl.bind("SUPER + SHIFT + S", (hl.dsp.window.move({ workspace = "special" })))
hl.bind("SUPER + mouse:272", (hl.dsp.window.drag()), {
  ["mouse"] = true
})
hl.bind("SUPER + mouse:273", (hl.dsp.window.resize()), {
  ["mouse"] = true
})
hl.bind("XF86AudioRaiseVolume", (hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+")), {
  ["locked"] = true,
  ["repeating"] = true
})
hl.bind("XF86AudioLowerVolume", (hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")), {
  ["locked"] = true,
  ["repeating"] = true
})
hl.bind("SHIFT + XF86AudioRaiseVolume", (hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ 5%+")), {
  ["locked"] = true,
  ["repeating"] = true
})
hl.bind("SHIFT + XF86AudioLowerVolume", (hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-")), {
  ["locked"] = true,
  ["repeating"] = true
})
hl.bind("XF86AudioMute", (hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")), {
  ["locked"] = true
})
hl.bind("SHIFT + XF86AudioMute", (hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")), {
  ["locked"] = true
})
hl.bind("XF86AudioMicMute", (hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")), {
  ["locked"] = true
})
hl.bind("XF86MonBrightnessDown", (hl.dsp.exec_cmd("hyprctl hyprsunset gamma -10; qs ipc call osd brightness")), {
  ["locked"] = true,
  ["repeating"] = true
})
hl.bind("XF86MonBrightnessUp", (hl.dsp.exec_cmd("hyprctl hyprsunset gamma +10; qs ipc call osd brightness")), {
  ["locked"] = true,
  ["repeating"] = true
})
hl.bind("XF86AudioPlay", (hl.dsp.exec_cmd("playerctl play-pause")), {
  ["locked"] = true
})
hl.bind("XF86AudioNext", (hl.dsp.exec_cmd("playerctl next")), {
  ["locked"] = true
})
hl.bind("XF86AudioPrev", (hl.dsp.exec_cmd("playerctl previous")), {
  ["locked"] = true
})
hl.bind("switch:on:Lid Switch", (hl.dsp.exec_cmd([[hyprctl keyword monitor "eDP-1,disable"]])), {
  ["locked"] = true
})
hl.bind("switch:off:Lid Switch", (hl.dsp.exec_cmd([[hyprctl keyword monitor "eDP-1,1920x1200,0x0,1.2"]])), {
  ["locked"] = true
})
hl.bind("SUPER + Tab", (function()
  hl.dispatch(hl.dsp.window.cycle_next())
  hl.dispatch(hl.dsp.window.bring_to_top())
end
))
hl.bind("SUPER + R", (function()
  if hl.get_active_window().fullscreen == 1 then
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
  elseif hl.get_active_window().fullscreen == 2 then
    hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))
  else
    hl.dispatch(hl.dsp.layout("colresize +conf"))
  end
end
))
hl.bind("SUPER + SHIFT + E", (function()
  if hl.get_active_window().floating then
    hl.dispatch(hl.dsp.window.move({ direction = "right" }))
  else
    hl.dispatch(hl.dsp.layout("swapcol r"))
  end
end
))
hl.bind("SUPER + SHIFT + Y", (function()
  if hl.get_active_window().floating then
    hl.dispatch(hl.dsp.window.move({ direction = "left" }))
  else
    hl.dispatch(hl.dsp.layout("swapcol l"))
  end
end
))
hl.bind("SUPER + E", (hl.dsp.layout("focus r")))
hl.bind("SUPER + Y", (hl.dsp.layout("focus l")))
hl.bind("SUPER + SHIFT + Right", (function()
  if hl.get_active_window().floating then
    hl.dispatch(hl.dsp.window.move({ direction = "right" }))
  else
    hl.dispatch(hl.dsp.layout("swapcol r"))
  end
end
))
hl.bind("SUPER + SHIFT + Left", (function()
  if hl.get_active_window().floating then
    hl.dispatch(hl.dsp.window.move({ direction = "left" }))
  else
    hl.dispatch(hl.dsp.layout("swapcol l"))
  end
end
))
hl.bind("SUPER + Right", (hl.dsp.layout("focus r")))
hl.bind("SUPER + Left", (hl.dsp.layout("focus l")))
hl.bind("SUPER + C", (function()
  local win = hl.get_active_window()
  hl.config({ scrolling = { focus_fit_method = 0 } })
  hl.dispatch(hl.dsp.focus({ window = win }))
  hl.config({ scrolling = { focus_fit_method = 1 } })
end
))
hl.bind("SUPER + SHIFT + R", (hl.dsp.submap("resize")))
hl.bind("SUPER + M", (hl.dsp.submap("move")))
hl.bind("SUPER + code:10", (hl.dsp.focus({ workspace = 1 })))
hl.bind("SUPER + SHIFT + code:10", (hl.dsp.window.move({ workspace = 1 })))
hl.bind("SUPER + code:11", (hl.dsp.focus({ workspace = 2 })))
hl.bind("SUPER + SHIFT + code:11", (hl.dsp.window.move({ workspace = 2 })))
hl.bind("SUPER + code:12", (hl.dsp.focus({ workspace = 3 })))
hl.bind("SUPER + SHIFT + code:12", (hl.dsp.window.move({ workspace = 3 })))
hl.bind("SUPER + code:13", (hl.dsp.focus({ workspace = 4 })))
hl.bind("SUPER + SHIFT + code:13", (hl.dsp.window.move({ workspace = 4 })))
hl.bind("SUPER + code:14", (hl.dsp.focus({ workspace = 5 })))
hl.bind("SUPER + SHIFT + code:14", (hl.dsp.window.move({ workspace = 5 })))
hl.bind("SUPER + code:15", (hl.dsp.focus({ workspace = 6 })))
hl.bind("SUPER + SHIFT + code:15", (hl.dsp.window.move({ workspace = 6 })))
hl.bind("SUPER + code:16", (hl.dsp.focus({ workspace = 7 })))
hl.bind("SUPER + SHIFT + code:16", (hl.dsp.window.move({ workspace = 7 })))
hl.bind("SUPER + code:17", (hl.dsp.focus({ workspace = 8 })))
hl.bind("SUPER + SHIFT + code:17", (hl.dsp.window.move({ workspace = 8 })))
hl.bind("SUPER + code:18", (hl.dsp.focus({ workspace = 9 })))
hl.bind("SUPER + SHIFT + code:18", (hl.dsp.window.move({ workspace = 9 })))
hl.bind("SUPER + code:19", (hl.dsp.focus({ workspace = 10 })))
hl.bind("SUPER + SHIFT + code:19", (hl.dsp.window.move({ workspace = 10 })))
hl.define_submap("move", function()
  hl.bind("E", (hl.dsp.window.move({ x = 30, y = 0, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Y", (hl.dsp.window.move({ x = -30, y = 0, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("H", (hl.dsp.window.move({ x = 0, y = 30, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("A", (hl.dsp.window.move({ x = 0, y = -30, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Right", (hl.dsp.window.move({ x = 30, y = 0, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Left", (hl.dsp.window.move({ x = -30, y = 0, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Down", (hl.dsp.window.move({ x = 0, y = 30, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Up", (hl.dsp.window.move({ x = 0, y = -30, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("escape", (hl.dsp.submap("reset")))
end)

-- submaps.resize
hl.define_submap("resize", function()
  hl.bind("E", (hl.dsp.window.resize({ x = 20, y = 0, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Y", (hl.dsp.window.resize({ x = -20, y = 0, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("H", (hl.dsp.window.resize({ x = 0, y = -20, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("A", (hl.dsp.window.resize({ x = 0, y = 20, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Right", (hl.dsp.window.resize({ x = 20, y = 0, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Left", (hl.dsp.window.resize({ x = -20, y = 0, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Down", (hl.dsp.window.resize({ x = 0, y = -20, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("Up", (hl.dsp.window.resize({ x = 0, y = 20, relative = true })), {
    ["repeating"] = true
  })
  hl.bind("escape", (hl.dsp.submap("reset")))
end)
''
