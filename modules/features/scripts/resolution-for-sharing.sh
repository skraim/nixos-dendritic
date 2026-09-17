hyprctl eval '
    hl.config({ misc = { disable_autoreload = true } })
    hl.config({ cursor = { no_hardware_cursors = 1 } })
    hl.monitor({ output="desc:Xiaomi Corporation Mi Monitor", mode="1920x1080@100Hz", position="auto-right" })
'

sleep 2;
matugen image ~/Pictures/wallpapers/wp12329531-nixos-wallpapers.png --source-color-index 0
