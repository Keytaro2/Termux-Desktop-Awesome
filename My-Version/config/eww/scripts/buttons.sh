#!/bin/bash

# Cached folder to save simulated states
CACHE_DIR="$HOME/.cache/eww_toggles"
mkdir -p "$CACHE_DIR"

BOTON="$1"   # wifi, vol, air, bri, bt, mic, crop, sync
ACCION="$2"  # status o toggle

# Default state (WiFi starts on 'on', the others off 'off')
if [ "$BOTON" = "wifi" ]; then
    DEFAULT="on"
else
    DEFAULT="off"
fi

FILE="$CACHE_DIR/$BOTON"

# If the status file does not exist, it is created
if [ ! -f "$FILE" ]; then
    echo "$DEFAULT" > "$FILE"
fi

CURRENT=$(cat "$FILE")

if [ "$ACCION" = "status" ]; then
    # Returns the current state to the Eww defpoll
    echo "$CURRENT"
elif [ "$ACCION" = "toggle" ]; then
    # Reverse the state by clicking
    if [ "$CURRENT" = "on" ]; then
        NEW="off"
        # Here you can enter real commands in the future (e.g., cmd_to_disable_wifi)
    else
        NEW="on"
        # Here you can enter real commands in the future (e.g., cmd_to_activate_wifi)
    fi
    echo "$NEW" > "$FILE"
    echo "$NEW"
fi
