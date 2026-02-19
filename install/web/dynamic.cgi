#!/bin/bash
echo "Content-type: text/html"
echo ""

CONF="/etc/default/czadsb.cfg"

if [ -f "$CONF" ]; then
    RPIMONITOR=$(grep "^RPIMONITOR=" /etc/default/czadsb.cfg | cut -d'"' -f2)
    if [[ "${RPIMONITOR}" == "enable" ]] || [[ "${RPIMONITOR}" == "disable" ]];then
        echo '<a href="/rpimonitor/" class="btn">Rpimonitor</a>'
    fi

    OGN=$(grep "^OGN=" /etc/default/czadsb.cfg | cut -d'"' -f2)
    if [[ "${OGN}" == "enable" ]] || [[ "${OGN}" == "disable" ]];then
        echo '<a href="/ogn.html" class="btn">OGN staus</a>'
    fi

    FR24=$(grep "^FR24=" /etc/default/czadsb.cfg | cut -d'"' -f2)
    if [[ "${FR24}" == "enable" ]] || [[ "${FR24}" == "disable" ]] || [[ "${FR24}" == "install" ]];then
        echo '<a href="https://www.flightradar24.com" target="_blank" class="btn" style="border-color: #ffaa00;">Flightradar24</a>'
    fi

    ADSBLOL=$(grep "^ADSBLOL=" /etc/default/czadsb.cfg | cut -d'"' -f2)
    if [[ "${ADSBLOL}" == "enable" ]] || [[ "${ADSBLOL}" == "disable" ]] || [[ "${ADSBLOL}" == "install" ]];then
        echo '<a href="https://www.adsb.lol/" target="_blank" class="btn" style="border-color: #ffaa00;">ADSB.lol</a>'
    fi

    ADSBEXCHANGE=$(grep "^ADSBEXCHANGE=" /etc/default/czadsb.cfg | cut -d'"' -f2)
    if [[ "${ADSBEXCHANGE}" == "enable" ]] || [[ "${ADSBEXCHANGE}" == "disable" ]] || [[ "${ADSBEXCHANGE}" == "install" ]];then
        echo '<a href="https://globe.adsbexchange.com/" target="_blank" class="btn" style="border-color: #ffaa00;">ADS-B Exchange</a>'
    fi
fi
