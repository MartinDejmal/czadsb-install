#!/bin/bash

# Vynucení standardního prostøedí (teèky, anglický formát)
export LC_ALL=C

echo "Content-type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# Získání všech TCP spojení (bez hlavièky)
# ss -tn: -t (tcp), -n (numerické adresy/porty)
DATA=$(ss -tn | tail -n +2)

echo "["
echo "$DATA" | awk '
BEGIN { first = 1 }
{
    # $4 je lokální adresa:port, $5 je vzdálená adresa:port

    # Parsování lokálního portu
    split($4, l_addr, ":");
    l_port = l_addr[length(l_addr)];

    # Parsování vzdálené IP a portu
    split($5, r_addr, ":");
    r_port = r_addr[length(r_addr)];
    
    r_ip = "";
    for (i=1; i < length(r_addr); i++) {
        r_ip = (i==1 ? "" : r_ip ":") r_addr[i];
    }
    # Odstranìní závorek u IPv6 adres
    gsub(/[\[\]]/, "", r_ip);

    # JSON výstup (lokální port, vzdálená IP, vzdálený port)
    if (!first) printf ",\n";
    printf "  { \"local_port\": \"%s\", \"remote_ip\": \"%s\", \"remote_port\": \"%s\" }", l_port, r_ip, r_port;
    first = 0;
}
END { printf "\n" }
'
echo "]"
