#!/bin/bash

# 3. HTTP Hlavičky (odesíláme jen když budeme skutečně vypisovat HTML)
echo "Content-type: text/html"
echo ""

# 1. Načtení a validace konfigurace
CONF="/etc/default/czadsb.cfg"
PIAWARE_STATE="none"

if [ -f "$CONF" ]; then
    PIAWARE_STATE=$(grep "^PIAWARE=" "$CONF" | cut -d'"' -f2)
    if [[ "${PIAWARE_STATE}" != "enable" ]] && [[ "${PIAWARE_STATE}" != "disable" ]]; then
        exit 0
    fi
else
    exit 0
fi


# 2. Kontrola existence stavového souboru
JSON_FILE="/run/piaware/status.json"
if [ ! -f "$JSON_FILE" ]; then
    exit 0
fi

# --- Pomocné funkce pro parsování ---
get_val()  { grep -Po "\"$1\"\s*:\s*\"\K[^\"]+" "$JSON_FILE"; }
get_num()  { grep -Po "\"$1\"\s*:\s*\K[0-9]+" "$JSON_FILE"; }
get_bool() { grep -Po "\"$1\"\s*:\s*\K[a-z]+" "$JSON_FILE"; }
get_status() { sed -n "/\"$1\"/,/}/p" "$JSON_FILE" | grep -Po '"status"\s*:\s*"\K[^"]+'; }
get_msg()    { sed -n "/\"$1\"/,/}/p" "$JSON_FILE" | grep -Po '"message"\s*:\s*"\K[^"]+'; }

get_color() {
    case "$1" in
        "green")  echo "#28a745" ;;
        "yellow") echo "#ffc107" ;;
        "red")    echo "#dc3545" ;;
        *)        echo "rgba(255,255,255,0.2)" ;;
    esac
}

# --- Logika pro expiraci PiAware tlačítka ---
EXPIRY=$(get_num "expiry")
NOW=$(date +%s%3N)
[ ${#NOW} -lt 13 ] && NOW=$(($(date +%s) * 1000))

DIFF=$((NOW - EXPIRY))
# 1 minuta = 60000 ms
if [ "$DIFF" -gt 60000 ]; then
    PIA_COLOR="#dc3545" # Červená (starší než 1 min)
else
    PIA_COLOR="#00a0e2" # Modrá (OK)
fi

# --- Generování HTML ---

# Hlavní tlačítko PiAware
SITE_URL=$(get_val "site_url")
echo "<a href=\"$SITE_URL\" target=\"_blank\" class=\"btn\" style=\"border-color: $PIA_COLOR;\">PiAware</a>"

# Status kontrolky
SECTIONS=("piaware" "adept" "mlat" "radio" "gps")
for SEC in "${SECTIONS[@]}"; do
    STATUS=$(get_status "$SEC")
    if [ -n "$STATUS" ]; then
        MSG=$(get_msg "$SEC")
        COLOR=$(get_color "$STATUS")
        echo "<a href=\"#\" class=\"btn\" title=\"$MSG\" style=\"border-color: $COLOR; flex: 0 1 auto; min-width: 80px; font-size: 0.8rem;\">${SEC^^}</a>"
    fi
done

# UAT Status
if [ "$(get_bool "uat_enabled")" = "true" ]; then
    echo "<a href=\"#\" class=\"btn\" style=\"border-color: #28a745; flex: 0 1 auto; min-width: 80px; font-size: 0.8rem;\">UAT</a>"
fi
