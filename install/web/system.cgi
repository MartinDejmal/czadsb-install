#!/bin/bash

# Vynucení standardního C prostredi (tecky v cislech)
export LC_ALL=C

# HTTP Hlavičky
echo "Content-type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# --- 1. Vypocet vytizeni CPU ---
get_cpu_ticks() {
    grep '^cpu ' /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8+$9+$10, $5+$6}'
}
read -r total1 idle1 < <(get_cpu_ticks)
sleep 1
read -r total2 idle2 < <(get_cpu_ticks)

diff_total=$((total2 - total1))
diff_idle=$((idle2 - idle1))

if [ "$diff_total" -gt 0 ]; then
    CPU_USAGE=$(awk "BEGIN {printf \"%.1f\", 100 * (1 - $diff_idle / $diff_total)}")
else
    CPU_USAGE="0.0"
fi

# --- 2. Teplota CPU ---
TEMP_PATH=$(ls /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n 1)
if [ -n "$TEMP_PATH" ]; then
    CPU_TEMP=$(awk "BEGIN {printf \"%.1f\", $(cat $TEMP_PATH)/1000}")
else
    CPU_TEMP=null
fi

# --- 3. Load Average ---
read -r L1 L5 L15 REST < /proc/loadavg
LOAD1=$(printf "%.2f" "$L1")
LOAD5=$(printf "%.2f" "$L5")
LOAD15=$(printf "%.2f" "$L15")

# --- 4. Pameti RAM (MB) ---
read -r MEM_TOTAL MEM_USED MEM_FREE MEM_BUFF < <(free -m | awk '/Mem:/ {print $2, $3, $4, $6}')

# --- 5. Disk (/) v MB ---
read -r DISK_TOTAL DISK_USED DISK_PCT < <(df -m / | awk 'NR==2 {print $2, $3, $5}' | tr -d '%')

# --- 6. Uptime (v sekundach) ---
UPTIME_SEC=$(cut -d' ' -f1 /proc/uptime)

# --- GENEROVANI ZPLOSTELEHO JSONU ---
cat <<EOF
{
  "uptime_seconds": $UPTIME_SEC,
  "load_average": {
    "1m": $LOAD1,
    "5m": $LOAD5,
    "15m": $LOAD15
  },
  "cpu": {
    "temp_c": $CPU_TEMP,
    "usage_percent": $CPU_USAGE
  },
  "memory_mb": {
    "total": $MEM_TOTAL,
    "used": $MEM_USED,
    "free": $MEM_FREE,
    "buffered_cached": $MEM_BUFF
  },
  "disk_root": {
    "total_mb": $DISK_TOTAL,
    "used_mb": $DISK_USED,
    "percent_used": $DISK_PCT
  },
  "timestamp": $(date +%s)
}
EOF
