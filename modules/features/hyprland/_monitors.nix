{
  lib,
  monitors,
}:
lib.concatMapStrings (monitor:
  #lua
  ''
    hl.monitor({
      mode = "${
      if monitor.width != null
      then "${toString monitor.width}x${toString monitor.height}@${toString monitor.refreshRate}Hz"
      else "preferred"
    }",
      output = "${monitor.name}",
      position = "${toString monitor.x}x${toString monitor.y}",
      scale = "${monitor.scale}"
    })
  '')
monitors
