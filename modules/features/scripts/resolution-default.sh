hyprctl eval '
    hl.config({ misc = { disable_autoreload = false } })
    hl.config({ cursor = { no_hardware_cursors = 2 } })
    hl.monitor({ output="desc:Xiaomi Corporation Mi Monitor", mode="3440x1440@100Hz", position="1600x-50" })
'

sleep 2;
matugen image "$(find ~/pictures/wallpapers -type f | shuf -n 1)" --source-color-index 0
