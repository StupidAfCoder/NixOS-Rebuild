#!/usr/bin/env bash
set -uo pipefail

# ---- CPU % (delta over ~200ms) ----
read_cpu() {
    read -r _ u n s i io irq sirq st _ < /proc/stat
    echo "$((u+n+s+i+io+irq+sirq+st)) $i"
}
read -r total1 idle1 <<< "$(read_cpu)"
sleep 0.2
read -r total2 idle2 <<< "$(read_cpu)"
dtotal=$((total2-total1))
didle=$((idle2-idle1))
cpu_pct=0
if [ "$dtotal" -gt 0 ]; then
    cpu_pct=$(( (100*(dtotal-didle)) / dtotal ))
fi

# ---- RAM ----
mem_total_kb=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
mem_avail_kb=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
mem_used_kb=$((mem_total_kb - mem_avail_kb))
ram_pct=$(( (100*mem_used_kb) / mem_total_kb ))
ram_used_gb=$(awk -v k="$mem_used_kb" 'BEGIN{printf "%.1f", k/1024/1024}')
ram_total_gb=$(awk -v k="$mem_total_kb" 'BEGIN{printf "%.1f", k/1024/1024}')

# ---- GPU (nvidia-smi) ----
gpu_pct=-1
gpu_temp=-1
gpu_mem_used=0
gpu_mem_total=0
if command -v nvidia-smi >/dev/null 2>&1; then
    IFS=',' read -r gpu_pct gpu_mem_used gpu_mem_total gpu_temp < <(
        nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
                   --format=csv,noheader,nounits 2>/dev/null | tr -d ' '
    )
fi

# ---- CPU temp: adjust the grep label to match YOUR `sensors` output ----
cpu_temp=-1
if command -v sensors >/dev/null 2>&1; then
    cpu_temp=$(sensors 2>/dev/null | grep -m1 -E "Package id 0|Tctl|Tdie" | grep -oP '\+\K[0-9]+' | head -1)
    [ -z "$cpu_temp" ] && cpu_temp=-1
fi

echo "${cpu_pct},${ram_pct},${ram_used_gb},${ram_total_gb},${gpu_pct},${gpu_temp},${gpu_mem_used},${gpu_mem_total},${cpu_temp}"