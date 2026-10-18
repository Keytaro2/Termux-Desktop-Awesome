#!/usr/bin/env bash
# Botones Copy / Delete del popup de captura. Ya no usa eww ni jq.
# Uso: screenshot_actions.sh copy|delete RUTA_IMAGEN
ACTION="$1"
IMG="$2"

case "$ACTION" in
  copy)
    [ -f "$IMG" ] || exit 1
    if command -v xclip >/dev/null 2>&1; then
      xclip -selection clipboard -t image/png -i "$IMG" >/dev/null 2>&1 &
      disown 2>/dev/null
    elif command -v termux-clipboard-set >/dev/null 2>&1; then
      termux-clipboard-set "$IMG"
    fi
    ;;
  delete)
    rm -f "$IMG"
    ;;
esac
exit 0
