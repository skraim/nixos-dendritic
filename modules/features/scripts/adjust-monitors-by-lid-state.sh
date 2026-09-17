LID_STATE=$(cat /proc/acpi/button/lid/*/state | grep -i 'state:' | awk '{print $2}')

EXTERNAL_MONITORS=$(hyprctl monitors | grep -v 'eDP-1' | grep '^Monitor' | wc -l)

if [[ "$LID_STATE" == "closed" && "$EXTERNAL_MONITORS" -ge 1 ]]; then
    hyprctl keyword monitor "eDP-1, disable"
fi
