#!/bin/bash
# Skript pro instalaci fwd ADSB dat pomoci readsb (puvodne adsbfwd)

# Instalace:
#   bash -c "$(wget -nv -O - https://rxw.cz/adsb/install/install-adsbfwd2.sh)"

# Jen odkaz na zajimavy monitor adsb dat: https://github.com/juei-dev/adsbmonitor?tab=readme-ov-file

# Nazev programu / sluzby
ADSBFWD_NAME="czadsbfwd"
# Typ SW pro predavani dat [ adsbfwd | readsb | direct ]
ADSBFWD_TYPE="readsb"
# Cesta ke konfiguracnimu souboru
ADSBFWD_CFG="/etc/default/${ADSBFWD_NAME}"
# Cesta k programu readsb
ADSBFWD_COMMAND="/usr/bin/readsb"
# Verze ReADSB
#REA_V="3.16.8"
REA_V="last"
# Adresa deb balicku pro CzADSB
URL_DEB="https://rxw.cz/dists"

# Adresa, port a protokol zdroje dat [ IP/DNS_url,port,protokol ]
ADSBFWD_SRC="127.0.0.1,30005,beast_in"
# Adresa a port kam se data posilaji [ IP/DNS_url,port ]
ADSBFWD_DST="feed.czadsb.cz,30004"
# Zalozni IP adresa
ADSBFWD_BAC="feed.rxw.cz,30004"
# Jedinecne UUID pro identifikaci prijimace
STATION_UUID=$(cat /proc/sys/kernel/random/uuid)


# Over prava na uzivatele root
[ -z ${SUDO} ] && SUDO=""
if [[ "$(id -u)" != "0" ]] && [[ ${SUDO} == "" ]];then
    echo "ERRROR: Instalaci je nutne spustit pod uzivatele root nebo z root pravy !"
    echo
    exit 3
fi

# Skontroluj parametr umisteni konfiguracniho souboru a pripadne jej nacti
if [[ -n $1 ]] && [[ -s $1 ]];then
    ADSBFWD_CFG=$1
    ADSBFWD_FILE="true"
elif [[ -n ${CFG} ]] && [[ -s ${CFG} ]];then
    ADSBFWD_CFG=${CFG}
    ADSBFWD_FILE="true"
elif [[ -s "/etc/default/czadsb.cfg" ]];then
    grep ADSBFWD_TYPE=\"readsb\" /etc/default/czadsb.cfg
    if [ $? == 0 ];then
        ADSBFWD_CFG="/etc/default/czadsb.cfg"
        ADSBFWD_FILE="true"
    else
        ADSBFWD_FILE="false"
    fi
else
    ADSBFWD_FILE="false"
fi


# Nacti jiz vytvorenou konfiguraci
if [[ -s ${ADSBFWD_CFG} ]];then
    echo "* Konfigurace se nacte z \"${ADSBFWD_CFG}\""
    . ${ADSBFWD_CFG}
else
    if [[ -s "/etc/default/czadsb.cfg" ]];then
        UUID=$(awk -F\" '/STATION_UUID/ {print $2}' /etc/default/czadsb.cfg)
        STATION_UUID=${UUID}
        echo "* Z nastaveni CzADSB byl prevzat UUID ${UUID}"
    fi
fi


# Instalace Readsb, jen pokud jiz neexistuje
if command -v ${ADSBFWD_COMMAND} &>/dev/null ;then
    echo "Software ReADSB je na systemu jiz nainstalovan"
else
    # Nacti verzi systemu
    . /etc/os-release
    ARCH=$(dpkg --print-architecture)
    echo
    echo "Detekovan system: ${PRETTY_NAME} - ${ARCH}"
    echo
    # Uklid stare instalacni balicky
    $SUDO rm -f ./readsb_*.deb
    # Stahni deb balicky pro konkretni architekturu
    WGET_URL="${URL_DEB}/${VERSION_CODENAME}/readsb_${REA_V}_${ARCH}.deb"
    echo "* Ztahuji ${WGET_URL}"
    wget -nv ${WGET_URL}
    if [ -f ./readsb_${REA_V}_${ARCH}.deb ]; then
        echo
        echo "* Instaluji ReADSB klienta"
        $SUDO dpkg -i readsb*.deb
    else
        echo
        echo "* ERROR:"
        echo "Pro Debian ${VERSION_CODENAME} ${ARCH} neni readsb v. ${REA_V} k dispozici."
        echo "Prosim kontaktujte z touto informaci autora skriptu."
        exit 3
    fi
fi


echo
echo "* Vytvorim konfiguracni soubor pro ${ADSBFWD_NAME}"
CONFIG_SAVE="false"
if ${ADSBFWD_FILE} ;then
    echo "  - pouzije se ${ADSBFWD_CFG}"
else
    echo "  - vytvori se ${ADSBFWD_CFG}"
    CONFIG_SAVE="false"
    if [ -e ${ADSBFWD_CFG} ];then
        echo -n "Konfiguracni soubor pro ${ADSBFWD_NAME} jiz existuje. Chcete skutecne soubor prepsat ? [a/N]";
        read X
        echo
        [ "$X" == "a" ] || [ "$X" == "y" ] && CONFIG_SAVE="true"
    else
        CONFIG_SAVE="true"
    fi
    if [ "${CONFIG_SAVE}" == "true" ];then
        $SUDO touch ${ADSBFWD_CFG}
        $SUDO chmod 666 ${ADSBFWD_CFG}
        echo
        echo "* Nastaveni vychozi konfigurace ${ADSBFWD_NAME}.conf"
        /bin/cat <<EOM >${ADSBFWD_CFG}
# Konfigurace pro ADSBfwd

# Typ SW pro predavani dat [ adsbfwd | readsb | direct ]
ADSBFWD_TYPE="readsb"

# Adresa a port kam se data posilaji [ IP/DNS_url,port ]
ADSBFWD_SRC="${ADSBFWD_SRC}"

# Adresa kam data chceme posilat
ADSBFWD_DST="${ADSBFWD_DST}"

# Zalozni adresa
ADSBFWD_BAC="${ADSBFWD_BAC}"

# Jedinecne UUID pro identifikaci prijimace. Pouzivejte pridelene pro konkretni prijimac
STATION_UUID="${STATION_UUID}"
EOM
    fi
fi


# Vytvoreni systemctrl
echo
echo "* Nastaveni CzADSBfwd jako slozby"
SERVICE_FILE=/lib/systemd/system/${ADSBFWD_NAME}.service
$SUDO touch ${SERVICE_FILE}
$SUDO chmod 777 ${SERVICE_FILE}

/bin/cat <<EOM >${SERVICE_FILE}
[Unit]
Description=ReADSB fwd for CzADSB
Wants=network.target
After=network.target

[Service]
EnvironmentFile=${ADSBFWD_CFG}
User=readsb
RuntimeDirectory=readsb
RuntimeDirectoryMode=0755
#ExecStart=/usr/bin/readsb --quiet --lat=\${STATION_LAT} --lon=\${STATION_LON} --net --net-connector=\${ADSBFWD_SRC} --net-connector=\${ADSBFWD_DST},beast_reduce_plus_out,uuid=\${STATION_UUID},\${ADSBFWD_BAC}
ExecStart=/usr/bin/readsb --quiet --net --net-connector=\${ADSBFWD_SRC} --net-connector=\${ADSBFWD_DST},beast_reduce_plus_out,uuid=\${STATION_UUID},\${ADSBFWD_BAC}
Type=simple
Restart=always
RestartSec=15
StartLimitInterval=1
StartLimitBurst=100
Nice=-5

[Install]
WantedBy=default.target
EOM

$SUDO chmod 644 ${SERVICE_FILE}
if [[ -z ${ADSBFWD} ]] || [[ "${ADSBFWD}" == "enable" ]];then
    $SUDO systemctl enable ${ADSBFWD_NAME}.service
fi
$SUDO systemctl restart ${ADSBFWD_NAME}.service
# Overeni a ukoncenei puvodni adsbfwd
systemctl status adsbfwd.service > /dev/null
if [[ $? == 0 ]];then
    $SUDO systemctl stop adsbfwd.service
    $SUDO systemctl disable adsbfwd.service
    UNIT=$(systemctl show -p FragmentPath --value adsbfwd.service)
    if [[ "$UNIT" != "" ]];then
        $SUDO rm "$UNIT"
    fi
fi

echo "Instalace CzADSBfwd ukoncena"
if ${CONFIG_SAVE};then
    echo "Nastavte konfiguracni soubor: ${ADSBFWD_NAME}"
else
    echo "Umisteni konfigurace: ${ADSBFWD_CFG}"
fi
echo

