# CzADSB - instalační skript

``Předmluva:``

Vzhledem k vývoji byl vytvořen nový pomocný instalační skript pro zdílení ADSB dat ze združením [CzADSB](https://czadsb.cz). 
Je testován pro nové verze Debian / Rasbian 12 a 13. Základní změny jsou:
* Konfigurační soubor je uložen v /etc/default/czadsb.cfg
* ModeMixer není funkční na nových verzích Debian. Proto skript jej již neinstaluje


``Instalace:``

Prvně si připravíme operační systém. Obecně při instalaci na Raspberry se doporučuje:
* Aktuální verze Raspbian 64 Bit Lite (nepředpokládám že na Rasbbery umístěné někde na půdě, či sožáru bude připojen monitor).
* Pokud chcete využívat MLAT data od FlightAware, tak použít jejich image [viz web](https://www.flightaware.com/adsb/piaware/build).

Po zprovozní systému pak spustíme instalační skript, který nás provede vlastní instalací:
```
bash -c "$(wget -O - https://raw.githubusercontent.com/CZADSB/czadsb-install/refs/heads/main/install-czadsb.sh)"
```

## Feedování vlastních Beast dat (ModeSMixer / dump1090) na CzADSB

Pokud už máte vlastní přijímač a nechcete instalovat celý stack, je možné použít jen forwarder dat:

1. Spusťte zjednodušený skript `onlyfwd-czadsb.sh`, který nainstaluje `adsbfwd` a `mlat-client`.
2. V souboru `/etc/default/czadsb.cfg` (případně `/etc/default/adsbfwd`) nastavte:
   * `ADSBFWD_SRC="IP:PORT"` – port, kde vám běží Beast stream (např. `127.0.0.1:30005` nebo port z ModeSMixeru),
   * `ADSBFWD_DST="czadsb.cz:50000"` – cílový server CzADSB.
3. Restartujte službu:
   ```bash
   sudo systemctl restart adsbfwd
   sudo systemctl status adsbfwd
   ```

`adsbfwd` přeposílá TCP stream transparentně (bez převodu formátu), takže když je na vstupu Beast, na výstupu je také Beast.

### Varianta přes Docker kontejner

Pro kontejnerové nasazení je v repozitáři skript `docker-adsbfwd.sh`, který:
* sestaví image s `socketForwarder.py`,
* vytvoří/spustí kontejner s `--network host`,
* předá mu source/target ve formátu `IP:PORT`.

Použití:
```bash
chmod +x docker-adsbfwd.sh
./docker-adsbfwd.sh 127.0.0.1:30005 czadsb.cz:50000 adsbfwd-czadsb
```

Parametry:
1. `ADSBFWD_SRC` (výchozí `127.0.0.1:30005`)
2. `ADSBFWD_DST` (výchozí `czadsb.cz:50000`)
3. `CONTAINER_NAME` (výchozí `adsbfwd-czadsb`)
