TS=$(ip -j a | jq -r '.[] | select(.ifname == "tailscale0") | .addr_info[] | select(.family == "inet")')
if [ -n "$TS" ]; then
    tailscale down
    printf '%s\n' 'vpn_status {"name":"Tailscale","state":"disconnected"}'
    exec notify-send -t 2000 -a "Tailscale" -i "$HOME/.icons/custom/vpn-off.svg" "Disconnected"
else
    vpn-disconnect.sh >/dev/null
    tailscale up
    printf '%s\n' 'vpn_status {"name":"Tailscale","state":"connected"}'
    exec notify-send -t 2000 -a "Tailscale" -i "$HOME/.icons/custom/vpn-on.svg" "Connected"
fi
