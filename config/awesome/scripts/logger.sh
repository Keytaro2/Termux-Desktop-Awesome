#!/usr/bin/env bash
# scripts/logger.sh — manda un aviso al popup de Awesome.
# Uso:  logger.sh APP TITULO MENSAJE [IMAGEN]
# Escribe una línea en ~/.cache/awesome-notify.queue; notifications/init.lua la lee
# con `tail -F` (no necesita awesome-client ni dbus).
Q="$HOME/.cache/awesome-notify.queue"
mkdir -p "$(dirname "$Q")"
clean() { printf '%s' "$1" | tr '\t\r\n' '   '; }
printf '%s\t%s\t%s\t%s\n' \
  "$(clean "${1:-System}")" "$(clean "${2:-Notification}")" \
  "$(clean "${3:-}")" "$(clean "${4:-}")" >> "$Q"
