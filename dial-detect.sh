#!/bin/bash
# shellcheck source=./utils.sh
source "$(dirname "$0")/utils.sh"

iface=$(detect_iface)
setup_network "$iface"

echo "=== DIAL/SSDP Discovery ==="
tcpdump -n -v -A "udp port 1900 or udp port 2900" -c 50 2>/dev/null | grep -i "LOCATION:" | sort -u > "$RESULTS_FILE" &
sleep 2
echo "$MSEARCH_PAYLOAD" | nc -v -u -w 1 -p 2900 239.255.255.250 1900
sleep 4
pkill -9 tcpdump 2>/dev/null || true

if [[ ! -s "$RESULTS_FILE" ]]; then
    echo "No DIAL devices found."
    exit 0
fi

while IFS= read -r line || [[ -n "$line" ]]; do
    url=$(echo "$line" | sed 's/.*LOCATION: //i' | tr -d '\r')
    [[ -z "$url" ]] && continue

    ip=$(echo "$url" | sed 's|http://||; s|:.*||')
    echo "-----------------------------------------------------------"
    echo "Device Description URL: $url"
    curl -s -i "$url" > "$DD_FILE" 2>/dev/null || true
    cat "$DD_FILE"

    # Special device handling
    if [[ "$url" == *":8060/dial/dd.xml"* ]]; then
        echo "→ Roku detected"
        curl -s -i "http://$ip:8060/query/active-app"
    elif [[ "$url" == *":60000/upnp/dev/"* ]]; then
        echo "→ Fire TV detected"
    fi

    surl=$(grep -i "Application-URL:" "$DD_FILE" | sed 's/.*: //' | tr -d '\r' | xargs)
    [[ -z "$surl" ]] && continue

    echo "DIAL Service URL: $surl"
    echo "Installed apps status:"

    for app in "${APP_LIST[@]}"; do
        lastchar="${surl: -1}"
        [[ "$lastchar" != "/" ]] && surl="${surl}/"
        appurl="${surl}$(urlencode "$app")"
        state=$(dial_poll_app "$appurl" "$app")
        printf "%-12s : %s\n" "$app" "$state"
    done
done < "$RESULTS_FILE"

restore_network "$iface"