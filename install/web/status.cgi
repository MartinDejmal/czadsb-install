#!/bin/bash
echo "Content-type: text/html"
echo ""

# --- 1. Teplota CPU ---
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    RAW_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    CPU_TEMP=$(awk "BEGIN {printf \"%.1f\", $RAW_TEMP/1000}")
else
    CPU_TEMP="N/A"
fi

# Barva teploty (Debian/Bash bezpecny zapis)
if [ "$CPU_TEMP" != "N/A" ]; then
    CPU_COL=$(awk "BEGIN {printf \"%.0f\", $RAW_TEMP/1000}")
    if [ "$CPU_COL" -gt 75 ]; then T_COL="#ff4444";
    elif [ "$CPU_COL" -gt 60 ]; then T_COL="#ffbb33";
    else T_COL="#ffffff"; fi
else
    T_COL="#ffffff"
fi

# --- 2. Vytizeni procesoru (Load) ---
CPU_LOAD=$(cat /proc/loadavg | cut -d' ' -f1)

# --- 3. Pamet RAM ---
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))

if [ "$MEM_PCT" -gt 90 ]; then M_COL="#ff4444";
elif [ "$MEM_PCT" -gt 75 ]; then M_COL="#ffbb33";
else M_COL="#ffffff"; fi

# --- 4. Vyuziti disku (/) ---
DISK_INFO=$(df -h / | awk 'NR==2 {print $2 " " $3 " " $5}')
DISK_TOTAL=$(echo $DISK_INFO | cut -d' ' -f1)
DISK_USED=$(echo $DISK_INFO | cut -d' ' -f2)
DISK_PCT=$(echo $DISK_INFO | cut -d' ' -f3 | tr -d '%')

if [ "$DISK_PCT" -gt 95 ]; then D_COL="#ff4444";
elif [ "$DISK_PCT" -gt 85 ]; then D_COL="#ffbb33";
else D_COL="#ffffff"; fi

# --- 5. Uptime ---
UPTIME=$(uptime -p | sed 's/^up //')

# --- Generování HTML ---

echo "<div class='status-item'><span class='status-label'>Teplota CPU</span><span class='status-value' style='color:$T_COL'>$CPU_TEMP °C</span></div>"
echo "<div class='status-item'><span class='status-label'>Load 1m</span><span class='status-value'>$CPU_LOAD</span></div>"
echo "<div class='status-item'><span class='status-label'>Paměť RAM</span><span class='status-value' style='color:$M_COL'>$MEM_USED / $MEM_TOTAL MB</span></div>"
echo "<div class='status-item'><span class='status-label'>Disk /</span><span class='status-value' style='color:$D_COL'>$DISK_USED / $DISK_TOTAL ($DISK_PCT%)</span></div>"
echo "<div class='status-item'><span class='status-label'>Uptime</span><span class='status-value'>$UPTIME</span></div>"
