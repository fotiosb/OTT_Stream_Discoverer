#!/bin/bash
# shellcheck source=./utils.sh
source "$(dirname "$0")/utils.sh"

echo "=== mDNS / Google Cast Discovery ==="
avahi-browse -rta > "$TEMP_DIR/mdns-all.txt" 2>/dev/null
avahi-browse -rt _googlecast._tcp | grep -i "address = \[" > "$TEMP_DIR/mdns-results.txt"

if [[ ! -s "$TEMP_DIR/mdns-results.txt" ]]; then
    echo "No Google Cast devices found."
    exit 0
fi

while IFS= read -r line || [[ -n "$line" ]]; do
    ip=$(echo "$line" | sed 's/.*address = \[//; s/\].*//')
    url="http://$ip:8008/ssdp/device-desc.xml"
    echo "-----------------------------------------------------------"
    echo "Chromecast at $ip → querying $url"
    curl -s -i "$url" > "$DD_FILE" 2>/dev/null || true
    cat "$DD_FILE"

    surl=$(grep -i "Application-URL:" "$DD_FILE" | sed 's/.*: //' | tr -d '\r' | xargs)
    [[ -z "$surl" ]] && continue

    echo "DIAL Service URL: $surl"
    echo "Apps status:"
    for app in "${APP_LIST[@]}"; do
        lastchar="${surl: -1}"
        [[ "$lastchar" != "/" ]] && surl="${surl}/"
        appurl="${surl}$(urlencode "$app")"
        state=$(dial_poll_app "$appurl" "$app")
        printf "%-12s : %s\n" "$app" "$state"
    done
done < "$TEMP_DIR/mdns-results.txt"

echo "Launching mkchromecast for active cast check (if installed)..."
mkchromecast 2>/dev/null || echo "mkchromecast not found"