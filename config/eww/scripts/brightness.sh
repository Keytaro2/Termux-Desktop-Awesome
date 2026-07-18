#!/bin/bash

# Si no se pasa ningún argumento, por defecto obtenemos el brillo
ACCION=${1:-"get"}

if [[ "$ACCION" == "set" ]]; then
    # Convertimos el porcentaje de eww (0-100) a la escala de Android (0-255)
    VALOR=$(echo "$2 * 2.55" | bc | awk '{print int($1+0.5)}')
    termux-brightness "$VALOR"

elif [[ "$ACCION" == "get" ]]; then
    # Leemos el brillo del sistema desde Android
    RAW=$(settings get system screen_brightness)
    
    # Convertimos la escala de Android (0-255) a porcentaje (0-100)
    PORCENTAJE=$(echo "$RAW / 2.55" | bc | awk '{print int($1+0.5)}')
    echo "$PORCENTAJE"
fi
