set -euo pipefail

disconnected=false
gateway=""

print_vpn_status() {
    local name="$1"
    local gateway="${2:-}"

    printf 'vpn_status '
    if [[ -n "$gateway" ]]; then
        jq -cn --arg name "$name" --arg gateway "$gateway" \
            '{name: $name, state: "disconnected", gateway: $gateway}'
    else
        jq -cn --arg name "$name" \
            '{name: $name, state: "disconnected"}'
    fi
}

if command -v tailscale >/dev/null 2>&1; then
    if ip -j a | jq -e '.[] | select(.ifname == "tailscale0") | .addr_info[] | select(.family == "inet")' >/dev/null 2>&1; then
        tailscale down
        print_vpn_status "Tailscale"
        disconnected=true
    fi
fi

if command -v snxctl >/dev/null 2>&1; then
    if snxctl status 2>/dev/null | grep -q "Connected since:"; then
        gateway="$(snxctl status | awk -F': +' '/Server name:/ {print $2; exit}')"
        snxctl disconnect
        print_vpn_status "SNX" "$gateway"
        disconnected=true
    fi
fi

if command -v nmcli >/dev/null 2>&1; then
    mapfile -t active_vpns < <(
        nmcli -t -f UUID,NAME,TYPE connection show --active \
        | awk -F: '$3 == "vpn" {print $1 "\t" $2}'
    )

    if (( ${#active_vpns[@]} > 0 )); then
        for vpn in "${active_vpns[@]}"; do
            uuid="${vpn%%$'\t'*}"
            vpn_name="${vpn#*$'\t'}"

            if [[ -z "$gateway" ]]; then
                gateway="$(
                    nmcli connection show "$uuid" \
                    | awk '
                        /vpn.data:/ {
                            if (match($0, /gateway = ([^,]+)/, m)) {
                                print m[1]
                                exit
                            }
                        }
                    '
                )"
            fi

            nmcli connection down "$uuid"
            print_vpn_status "$vpn_name" "$gateway"
            disconnected=true
        done
    fi
fi

if [[ "$disconnected" = false ]]; then
    printf '%s\n' 'vpn_status {"name":"none","state":"unchanged"}'
    exit 1
fi

msg_main="VPN disconnected."
msg_gw=""
[[ -n "$gateway" ]] && msg_gw+="Gateway: $gateway"

exec notify-send \
    -a "VPN" \
    -t 2000 \
    -i "$HOME/.icons/custom/vpn-off.svg" \
    "$msg_main" \
    "$msg_gw"
