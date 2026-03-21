#!/bin/bash
# Skript spousti mlat clienta pro CzADSB na zaklade konfiguracniho 
# souboru na ceste ulozene v promenne 'CONFIG_FILE' 
CONFIG_FILE="/etc/default/czadsb.cfg"

BINARY_DIR=`dirname $0`

# 1. Overeni existence konfiguracniho souboru
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Chyba: Konfiguracni soubor $CONFIG_FILE neexistuje!" >&2
    exit 1
fi

# 2. Nacteni konfigurace
source "$CONFIG_FILE"

# 3. Kontrola, zda je MLAT povolen
if [ "$MLAT" != "enable" ]; then
    echo "MLAT v konfiguraci neni povolen (MLAT=$MLAT)."
    exit 0
fi

# 4. Overeni existence binarky (pouzije MLAT_NAME z konfigurace)
if [ -z "$MLAT_NAME" ]; then
    echo "Chyba: V konfiguraci chybi definice MLAT_NAME!" >&2
    exit 1
fi

# 5. Overeni zadani umisteni prijmace
if [[ "$STATION_LAT" == 0 ]] || [[ "$STATION_LON" == 0 ]] || [[ "$STATION_ALT" == 0 ]]; then
    echo "Chyba: V konfiguraci chybi definice umisteni prijmace!"
    exit 1
fi

# 6. Overeni nazvu a uuid
if [[ "$STATION_NAME" == "" ]] || [[ "$STATION_UUID" == "0" ]]; then
    echo "Chyba: V konfiguraci chybi definice nazvu prijmace nebo uuid!"
    exit 1
fi

# 7. Overeni existence vlastniho programu
BINARY_PATH="$BINARY_DIR/$MLAT_NAME"
if [ ! -x "$BINARY_PATH" ]; then
    echo "Chyba: Soubor $BINARY_PATH neexistuje nebo neni spustitelny!" >&2
    exit 1
fi

# 8. Priprava parametru do pole (Array)
PARAMS=()

if [[ "$DUMP1090" == "enable" ]] || [[ "$DUMP1090" == "install" ]]; then
    PARAMS+=("--input-type" "dump1090")
elif [[ "$READSB" == "enable" ]] || [[ "$READSB" == "install" ]]; then
    PARAMS+=("--input-type" "beast")
else
    PARAMS+=("--input-type" "auto")
fi
PARAMS+=("--input-connect" "localhost:30005")
PARAMS+=("--no-udp")
PARAMS+=("--lat" "$STATION_LAT")
PARAMS+=("--lon" "$STATION_LON")
PARAMS+=("--alt" "$STATION_ALT")
PARAMS+=("--server" "$MLAT_SERVER")
PARAMS+=("--user" "$STATION_NAME")
PARAMS+=("--uuid" "$STATION_UUID")
if [ -n "$MLAT_FORMAT" ] && [ -n "$MLAT_RESULT" ]; then
    PARAMS+=("--results" "${MLAT_FORMAT},${MLAT_RESULT}")
fi

# 9. Spusteni klienta
# Pouzivame 'exec', aby proces klienta prevzal PID shellu (vhodne pro systemd)
echo "Spoustim $MLAT_NAME pro prijimac $STATION_NAME..."
exec "$BINARY_PATH" "${PARAMS[@]}"
