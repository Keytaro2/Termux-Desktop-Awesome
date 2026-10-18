#!/usr/bin/env bash
# Silencia / restaura el volumen. Ya no depende de eww: guarda el estado en un archivo.
F="$HOME/.cache/eww_toggles/vol_muted"
mkdir -p "$(dirname "$F")"
CURRENT_MUTED=$(cat "$F" 2>/dev/null || echo false)

if [ "$CURRENT_MUTED" = "false" ]; then
    cmd audio set-stream-volume 3 0 2>/dev/null || termux-volume music 0 2>/dev/null
    cmd audio set-ringer-mode 0 2>/dev/null || termux-volume ring 0 2>/dev/null
    echo true > "$F"
else
    cmd audio set-stream-volume 3 8 2>/dev/null || termux-volume music 8 2>/dev/null
    cmd audio set-ringer-mode 2 2>/dev/null || termux-volume ring 8 2>/dev/null
    echo false > "$F"
fi
