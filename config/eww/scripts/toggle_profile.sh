#!/bin/bash
CURRENT=$(eww get current_profile 2>/dev/null)
[ -z "$CURRENT" ] && CURRENT="1"

DIRECTION=${1:-"forward"}

if [ "$DIRECTION" == "forward" ]; then
    if [ "$CURRENT" == "1" ]; then NEXT="2"
    elif [ "$CURRENT" == "2" ]; then NEXT="3"
    elif [ "$CURRENT" == "3" ]; then NEXT="4"
    else NEXT="1"; fi
else
    if [ "$CURRENT" == "4" ]; then NEXT="3"
    elif [ "$CURRENT" == "3" ]; then NEXT="2"
    elif [ "$CURRENT" == "2" ]; then NEXT="1"
    else NEXT="4"; fi
fi

eww update current_profile="$NEXT"
--
# Save the profile number to Termux standard temporary directory for instant reading
echo "$NEXT" > /data/data/com.termux/files/usr/tmp/current_profile
