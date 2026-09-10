#!/usr/bin/env bash

set -euo pipefail

if command -v snxctl >/dev/null 2>&1; then
    if snxctl status 2>/dev/null | grep -q "Server name:"; then
        snxctl status \
            | awk -F': +' '/Server name:/ {print $2; exit}'
        exit 0
    fi
fi

if command -v nmcli >/dev/null 2>&1; then
    vpn_uuid=$(nmcli -t -f UUID,TYPE connection show --active \
        | awk -F: '$2 == "vpn" {print $1; exit}')

    if [[ -n "${vpn_uuid:-}" ]]; then
        nmcli connection show "$vpn_uuid" \
            | awk -F'= ' '/vpn.data:/ {
                if (match($0, /gateway = ([^,]+)/, m)) {
                    print m[1]
                    exit
                }
            }'
        exit 0
    fi
fi

ts_ip=$(ip -j a | jq -r '.[] | select(.ifname == "tailscale0") | .addr_info[] | select(.family == "inet") | .local' 2>/dev/null | head -1)
if [[ -n "$ts_ip" ]]; then
    echo "tailscale ($ts_ip)"
    exit 0
fi

echo "No active VPN detected" >&2
exit 1
