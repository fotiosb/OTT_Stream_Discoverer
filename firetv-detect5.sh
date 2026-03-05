#!/bin/bash
# shellcheck source=./utils.sh
source "$(dirname "$0")/utils.sh"

FIREIP=""
MITM=0
[[ "$1" == "--mitm" ]] && MITM=1

iface=$(detect_iface)
setup_network "$iface"

echo "=== Fire TV SSDP Discovery ==="
tcpdump -n -v -A "udp port 1900 or udp port 2900" -c 50 2>/dev/null | grep -i "LOCATION:" | sort -u > "$RESULTS_FILE" &
sleep 2
echo "$MSEARCH_PAYLOAD" | nc -v -u -w 1 -p 2900 239.255.255.250 1900
sleep 4
pkill -9 tcpdump 2>/dev/null || true

while IFS= read -r line || [[ -n "$line" ]]; do
    url=$(echo "$line" | sed 's/.*LOCATION: //i' | tr -d '\r')
    [[ "$url" == *":60000/upnp/dev/"* ]] && {
        FIREIP=$(echo "$url" | sed 's|http://||; s|:.*||')
        echo "Fire TV found at $FIREIP"
        break
    }
done < "$RESULTS_FILE"

if [[ -z "$FIREIP" ]]; then
    echo "No Fire TV found."
    restore_network "$iface"
    exit 1
fi

if [[ $MITM -eq 1 ]]; then
    echo "=== MITM MODE ACTIVATED ==="
    read -r -p "This will ARP-spoof and may break the device/network. Continue? (y/N) " confirm
    [[ "$confirm" != [yY] ]] && { echo "Aborted."; exit 1; }

    sysctl -w net.ipv4.ip_forward=1
    gatewayip=$(ip route show default | awk '/default/ {print $3}')
    arpspoof -i "$iface" -t "$FIREIP" -r "$gatewayip" > /dev/null 2>&1 &
    ARP_PID=$!

    echo "Sniffing DNS CNAMEs from Fire TV (30 seconds or Ctrl-C)..."
    timeout 30 tcpdump -i "$iface" -n -c 100 "host $FIREIP and udp port 53" 2>/dev/null | grep -oE 'CNAME [^. ]+\.[^ ]+' | awk '{print $2}' | sort -u
    echo "DNS domains seen: (above)"

    kill "$ARP_PID" 2>/dev/null || true
    sysctl -w net.ipv4.ip_forward=0
fi

restore_network "$iface"
echo "Done."