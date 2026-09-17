if [ "$(hyprctl activewindow -j | jq -r ".class")" = "steam" ]; then
    steam -shutdown
else
    hyprctl dispatch 'hl.dsp.window.kill()'
fi
