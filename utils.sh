#!/bin/bash
set -euo pipefail

# ====================== SHARED UTILS ======================

TEMP_DIR="/tmp/ott-discover-$$"
RESULTS_FILE="$TEMP_DIR/results.txt"
DD_FILE="$TEMP_DIR/device-desc.txt"

mkdir -p "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"; pkill -9 -f "arpspoof.*$FIREIP" 2>/dev/null || true; sysctl -w net.ipv4.ip_forward=0 2>/dev/null || true' EXIT

# Pure bash urlencode (no external command needed)
urlencode() {
    local string="${1}"
    local encoded=""
    local i c
    for ((i=0; i<${#string}; i++)); do
        c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) encoded+="$c" ;;
            *) printf -v encoded '%s%%%02X' "$encoded" "'$c" ;;
        esac
    done
    printf '%s' "$encoded"
}

detect_iface() {
    local iface
    iface=$(echo /sys/class/net/*/wireless | awk -F'/' '{print $5}')
    if [[ -z "$iface" || "$iface" == "*" ]]; then
        echo "ERROR: No wireless interface detected" >&2
        exit 1
    fi
    echo "$iface"
}

setup_network() {
    local iface="$1"
    ip link set "$iface" down
    ip link set "$iface" promisc on
    ip link set "$iface" up
    systemctl restart networking NetworkManager 2>/dev/null || true
    sleep 2
}

restore_network() {
    local iface="$1"
    ip link set "$iface" down
    ip link set "$iface" promisc off
    ip link set "$iface" up
    systemctl restart networking NetworkManager 2>/dev/null || true
}

# DIAL M-SEARCH payload (inline, no external file)
MSEARCH_PAYLOAD=$(cat <<'EOF'
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
MX: 3
ST: urn:dial-multiscreen-org:service:dial:1

EOF
)

# Common app list (expand as you wish)
APP_LIST=(
    Netflix
    YouTube
    PrimeVideo
    DisneyPlus
    Hulu
    HBO
    Spotify
    Plex
)

# Poll a single DIAL app URL and return state
dial_poll_app() {
    local appurl="$1"
    local appname="$2"
    local result
    result=$(curl -s --max-time 3 "$appurl" 2>/dev/null || echo "")
    if [[ ${#result} -gt 30 ]]; then
        echo "$result" | tr -d '\r' | sed -n 's/.*<state>\(.*\)<\/state>.*/\1/p' | xargs
    else
        echo "not_installed_or_unreachable"
    fi
}