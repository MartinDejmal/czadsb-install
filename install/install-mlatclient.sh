#!/bin/bash

# Skript pro instalaci mlat klienta jako czadsb-mlat
# Vytvori VENV prostredi, kde stahne aktualni verzi z gitu, 
# upravi drobne zmeny pro CzADSB, zkompiluje a nasledne po
# po sobe uklidi.
# Nasledne stahne spousteci skript a spustec sluzby.


# Nazev vlastniho programu a sluzby
MLAT_NAME="czadsb-mlat"
# Jmeno uzivatele pod kterym se spusti ADS-Bfwd
MLAT_USER="adsb"
# Cesta ke konfiguracnimu souboru
MLAT_CFG="/etc/default/${MLAT_NAME}"
# Cesta kde se vytvori VENV a provede nasledna instalace
PATH_BIN="/usr/local/share/czadsb"
# Cesta na zdroj dat na Gitu
PATH_GIT="https://github.com/wiedehopf/mlat-client.git"
# Cesta pro stazeni pomocnych skriptu
URL_SCRIPT="https://rxw.cz/adsb/install"

# Pred stazenim stavajici konfigurace si zazalohuj jmeno skriptu.
MLAT_NAME_NEW=$MLAT_NAME 

# Skontroluj parametr umisteni konfiguracniho souboru a pripadne jej nacti
if [[ -n $1 ]] && [[ -s $1 ]];then
    MLAT_CFG=$1
    MLAT_FILE="true"
    # Prevezmy, prednastav uzivatele
    [ ! -z ${CZADSB_USER} ] && MLAT_USER=${CZADSB_USER}
elif [[ -n ${CFG} ]] && [[ -s ${CFG} ]];then
    MLAT_CFG=${CFG}
    MLAT_FILE="true"
    # Prevezmy, prednastav uzivatele
    [ ! -z ${CZADSB_USER} ] && MLAT_USER=${CZADSB_USER}
elif [[ -s "/etc/default/czadsb.cfg" ]];then
    MLAT_CFG="/etc/default/czadsb.cfg"
    MLAT_FILE="true"
else
    MLAT_FILE="false"
fi

# Nasci jiz vytvorenou konfiguraci
if [[ -s ${MLAT_CFG} ]];then
    echo "* Konfigurace se nacte z \"${MLAT_CFG}\""
    source ${MLAT_CFG}
fi

# Over prava na uzivatele root
[ -z ${SUDO} ] && SUDO=""
if [[ "$(id -u)" != "0" ]] && [[ ${SUDO} == "" ]];then
    echo "ERRROR: Instalaci je nutne spustit pod uzivatele root nebo z root pravy !"
    echo
    exit 3
fi

# Over a vytvor uzivatele
grep "^${MLAT_USER}:" /etc/passwd > /dev/null
if [[ "$?" == "1" ]];then
    echo "* Vytvoreni uzivatele \"${MLAT_USER}\" pro spusteni ${MLAT_NAME}"
    $SUDO adduser --system --group --no-create-home --shell /bin/bash ${MLAT_USER}
else
    echo "* Uzivatel \"${MLAT_USER}\" jiz existuje"
fi

# Over puvodni a nove jmeno skriptu. Pripadne zrus spusteni puvodniho
if [ "$MLAT_NAME_NEW" != "$MLAT_NAME" ];then
    echo "* Nalezena stara verze mlat clienta. Odstranuji ..."
    $SUDO systemctl stop $MLAT_NAME.service
    $SUDO systemctl disable $MLAT_NAME.service
    $SUDO rm -f /lib/systemd/system/$MLAT_NAME.service
    $SUDO systemctl daemon-reload
    MLAT_NAME=$MLAT_NAME_NEW
    MLAT_SERVER="mlat.czadsb.cz:3109"
    MLAT_RESULT="127.0.0.1:30104"
    MLAT_FORMAT="beast,connect"
    MLAT_RESTART=false
else
    MLAT_RESTART=true
fi

# Vytvorime VENV prostredi
if [ -d $PATH_BIN ];then
    $SUDO rm -fr $PATH_BIN
fi
echo "* Vytvarim VENV prostredi"
$SUDO mkdir $PATH_BIN
$SUDO chmod 777 $PATH_BIN
python3 -m venv $PATH_BIN

# Prepneme se do VENV prostredi a stahneme zdroj z gitu
source "$PATH_BIN/bin/activate"
cd $PATH_BIN
echo "* Stahuji zdrojova data"
git clone $PATH_GIT

# Z PATH_GIT zjisteni nazev adrsare kam se zdroj ulozil
NAME_GIT="${PATH_GIT##*/}"      # Odstraníme vše před posledním '/' -> readsb.git
NAME_GIT="${NAME_GIT%.*}"       # Odstraníme příponu -> readsb

# Vnorime se do adresare zdroje, doinstalujeme chybejici programy a provedeme instalaci
cd $NAME_GIT
sed -i "s|default=('feed.adsbexchange.com', 31090))|default=('feed.czadsb.cz', 3109))|g" ./$NAME_GIT
echo "* Instaluji pomocne programy do VENV prostredi"
python3 -c "import setuptools" || python3 -m pip install setuptools
python3 -c "import asyncore"   || python3 -m pip install pyasyncore
echo "* Provadim vlastni kompilaci"
pip install .

# Vratime se vychoziho adresar, prekopirujeme vlastni program a ukliddime po sobe
echo "* uklizim po sobe ..."
cd $PATH_BIN
cp $PATH_BIN/bin/$NAME_GIT $PATH_BIN/$MLAT_NAME
rm -rf $PATH_BIN/bin/$NAME_GIT
deactivate

# Pokud neexistuje stavjici konfigurace, nainstaluj vzor
if [! $MLAT_FILE ];then
    echo "* Ukladam vzorovou konfiguraci do $MLAT_CFG"
    wget $URL_SCRIPT/$MLAT_NAME/$MLAT_NAME -O $MLAT_CFG
fi 

# Stahni spousteci skript a uprav vnem cestu na konfiguracni soubor
echo "* stahuji a nastavuji spousteci skript"
wget $URL_SCRIPT/$MLAT_NAME/$MLAT_NAME.sh -O $PATH_BIN/$MLAT_NAME.sh
sed -i "s|CONFIG_FILE=.*|CONFIG_FILE=\"$MLAT_CFG\"|g" $PATH_BIN/$MLAT_NAME.sh
chmod +x $PATH_BIN/$MLAT_NAME.sh

# Stazeni services, nastaveni platne cesty a uzivatele
echo "* Stahuji a nastavuji services" 
wget $URL_SCRIPT/$MLAT_NAME/$MLAT_NAME.service -O $PATH_BIN/$MLAT_NAME.service
sed -i "s|User=.*|User=$MLAT_USER|g" $PATH_BIN/$MLAT_NAME.service
sed -i "s|ExecStart=.*|ExecStart=\"$PATH_BIN/$MLAT_NAME.sh\"|g" $PATH_BIN/$MLAT_NAME.service
# presunuti a aktivovani vlastni sluzby
$SUDO mv $PATH_BIN/$MLAT_NAME.service /lib/systemd/system/$MLAT_NAME.service
$SUDO chown root:root /lib/systemd/system/$MLAT_NAME.service
$SUDO systemctl daemon-reload
$SUDO systemctl enable czadsb-mlat

# Zmen prava na prislusneho uzivatele
echo "* Nastavuji prava pro $MLAT_USER"
$SUDO chown -R $MLAT_USER:$MLAT_USER $PATH_BIN
$SUDO chmod 755 $PATH_BIN

# Spust sluzbu
$MLAT_RESTART && $SUDO systemctl restart czadsb-mlat 

