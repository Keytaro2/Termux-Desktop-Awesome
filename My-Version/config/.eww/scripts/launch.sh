#!/bin/bash

DIR="$HOME/.config/eww/menu1"

# =========================================
# GET CURSOR POSITION
# =========================================
X="${1:-0}"
Y="${2:-0}"

# =========================================
# CALCULATE SUBMENU POSITION
# =========================================
SUB_X=$((X + 290))
SUB_Y=$((Y + 250))

# Save the position in a temporary file (cache)
mkdir -p ~/.cache
echo "${SUB_X}x${SUB_Y}" > ~/.cache/menu1_5_pos

# =========================================
# CHECK EWW DAEMON
# =========================================
if ! eww -c "$DIR" ping &>/dev/null; then
    eww -c "$DIR" daemon &
    sleep 0.5
fi

# =========================================
# CLOSE PREVIOUS MENUS
# =========================================
eww -c "$DIR" close menu1 menu1_5 2>/dev/null

# =========================================
# OPEN MAIN MENU
# =========================================
eww -c "$DIR" open menu1 \
    --pos "${X}x${Y}" \
    --anchor "top left"
