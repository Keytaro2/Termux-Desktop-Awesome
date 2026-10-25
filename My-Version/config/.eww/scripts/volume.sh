#!/data/data/com.termux/files/usr/bin/bash

# Obtain data only once to save resources
stats=$(termux-volume)

# Extract max volume
max=$(echo "$stats" | jq '.[] | select(.stream == "music") | .max_volume' 2>/dev/null)

if [[ -z "$max" ]] || [[ "$max" -eq 0 ]]; then
    echo "0"
    exit 0
fi

# ==========================================
# WRITE LOGIC (When eww sends the {})
# ==========================================
if [[ -n "$1" ]]; then
    # eww sometimes sends decimals (e.g., 45.333), this removes the decimals so bash doesn't crash
    val="${1%.*}"
    
    # We convert the eww percentage to the cell phone range
    new_vol=$(( ( val * max + 50 ) / 100 ))
    
    # Safety limits
    if [[ "$new_vol" -gt "$max" ]]; then new_vol="$max"; fi
    if [[ "$new_vol" -lt 0 ]]; then new_vol=0; fi

    # We use the Termux API to change the volume
    termux-volume music "$new_vol" > /dev/null
    exit 0
fi

# ==========================================
# READ LOGIC (To update sys_vol)
# ==========================================
vol=$(echo "$stats" | jq '.[] | select(.stream == "music") | .volume' 2>/dev/null)

if [[ -z "$vol" ]]; then
    echo "0"
    exit 0
fi

# calculate percentages
percent=$(( vol * 100 / max ))

echo "$percent"
