#!/bin/bash

# Leemos en qué perfil estamos actualmente
CURRENT=$(eww get current_profile)

if [ "$CURRENT" == "1" ]; then
    eww -c ~/.config/eww/notifications open --toggle notifications
elif [ "$CURRENT" == "4" ]; then
    eww -c ~/.config/eww/actions2 open --toggle actions2
else
    # Para el perfil 2 y 3
    eww -c ~/.config/eww/actions1 open --toggle actions1
fi
