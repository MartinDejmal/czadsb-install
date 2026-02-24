#!/bin/bash

# /var/log/rpimonitor.log  - see v init.d       
# /var/lib/rpimonitor/updatestatus.txt

# Cesta k instalacnim skriptum
[[ -z ${INSTALL_URL} ]] && INSTALL_URL="https://rxw.cz/adsb/install"

# Over prava na uzivatele root
[ -z ${SUDO} ] && SUDO=""
if [[ "$(id -u)" != "0" ]] && [[ ${SUDO} == "" ]];then
    echo "ERRROR: Instalaci je nutne spustit pod uzivatele root nebo z root pravy !"
    echo
    exit 3
fi

echo "* Instalace zavislosti"
echo "------------------------------------->"
$SUDO apt-get update
$SUDO apt-get install -y --no-install-suggests --no-install-recommends librrds-perl libhttp-daemon-perl libjson-perl libipc-sharelite-perl libfile-which-perl libsnmp-extension-passpersist-perl aptitude
#$SUDO apt-get install -y libwww-perl
#$SUDO apt --fix-broken install -y
echo "-------------------------------------<"

echo "* Stazeni programu RpiMonitor a jeho instalace"
RPIMONITOR_URL="https://github.com/XavierBerger/RPi-Monitor-deb/raw/develop/packages/rpimonitor_latest.deb"
wget ${RPIMONITOR_URL} -O rpimonitor_latest.deb
$SUDO dpkg -i rpimonitor_latest.deb

$SUDO /usr/share/rpimonitor/scripts/updatePackagesStatus.pl
$SUDO /etc/init.d/rpimonitor update
rm rpimonitor_latest.deb

grep '# cs_CZ.UTF-8 UTF-8' /etc/locale.gen
if [ "$?" == "0" ];then
    echo "* Nastaveni jazykoveho prostredi"
    sudo sed -i 's/^# \(cs_CZ.UTF-8 UTF-8\)/\1/' /etc/locale.gen                # 1. Odkomentování požadovaných jazykù v souboru /etc/locale.gen
    sudo sed -i 's/^# \(en_GB.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo locale-gen                                                             # 2. Vygenerování zvolených locales
    sudo update-locale LANG=cs_CZ.UTF-8 LC_ALL=cs_CZ.UTF-8                      # 3. Nastavení výchozího jazyka systému
fi

echo "* Donastaveni RpiMonotru"
# Zobrazeni top3 aplikaci (presmerovani generovane stranky na shm)
$SUDO cp /usr/share/rpimonitor/web/addons/top3/top3.html /dev/shm/top3.html
$SUDO rm /usr/share/rpimonitor/web/addons/top3/top3.html
$SUDO ln -s /dev/shm/top3.html /usr/share/rpimonitor/web/addons/top3/top3.html
$SUDO cp /usr/share/rpimonitor/web/addons/top3/top3.cron /etc/cron.d/top3
$SUDO sed -i 's/#web.status.1.content.1/web.status.1.content.1/g' /etc/rpimonitor/template/cpu*.conf
# Zobrazi status nastavenych sluzeb
$SUDO wget -q ${INSTALL_URL}/rpimonitor/czadsb_service.conf -O /etc/rpimonitor/template/czadsb_service.conf
if [[ $(grep "czadsb_service.conf" /etc/rpimonitor/data.conf | wc -l) -eq 0 ]];then
    $SUDO sh -c 'echo "include=/etc/rpimonitor/template/czadsb_service.conf" >> /etc/rpimonitor/data.conf'
fi
# Oprava nacitani teploty na Raspberry
$SUDO wget -q ${INSTALL_URL}/rpimonitor/temperature.conf -O /etc/rpimonitor/template/temperature.conf
# Pridej templejty
$SUDO wget -q ${INSTALL_URL}/rpimonitor/addons-piaware.conf       -O /etc/rpimonitor/template/addons-piaware.conf
$SUDO wget -q ${INSTALL_URL}/rpimonitor/addons-ogn.conf           -O /etc/rpimonitor/template/addons-ogn.conf
$SUDO wget -q ${INSTALL_URL}/rpimonitor/addons-gps.conf           -O /etc/rpimonitor/template/addons-gps.conf
$SUDO wget -q ${INSTALL_URL}/rpimonitor/addons-glidertracker.conf -O /etc/rpimonitor/template/addons-glidertracker.conf
# Predpis pro Lighttpd
$SUDO wget -q ${INSTALL_URL}/rpimonitor/68-rpimonitor.conf        -O /etc/rpimonitor/68-rpimonitor.conf
# Presmerovani grafu na shm
$SUDO rm -rf /var/lib/rpimonitor/stat
$SUDO ln -s /dev/shm /var/lib/rpimonitor/stat
sleep 1
$SUDO systemctl restart rpimonitor.service

echo "* RpiMonitor je dostupny na IP "$(hostname -I)", port 8888."

