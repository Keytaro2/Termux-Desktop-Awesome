#!/bin/bash

# Si estamos en la carpeta principal (~), no mostramos nada
if [ "$PWD" = "$HOME" ]; then
    exit 0
fi

# Obtenemos solo el nombre de la carpeta actual
carpeta=$(basename "$PWD")

# Evaluamos qué icono usar
case "$carpeta" in
    ".config") echo " .config" ;;
    "awesome") echo " awesome" ;;
    "eww") echo "󰜬 eww" ;;
    "nvim") echo " nvim" ;;
    ".cargo") echo " .cargo" ;;
    ".icons"|"icons") echo " $carpeta" ;;
    ".ssh") echo "󰢬 .ssh" ;;
    ".gnupg") echo "󰢬 .gnupg" ;;
    ".npm") echo " .npm" ;;
    ".dbus") echo " .dbus" ;;
    ".cache") echo "󰃨 .cache" ;;
    "kitty") echo " kitty" ;;
    "xfce4") echo " xfce4" ;;
    "starship") echo " starship" ;;
    "mozilla"|"firefox") echo "󰈹 $carpeta" ;;
    "terminal"|"alacritty") echo " $carpeta" ;;
    "desktop") echo " desktop" ;;
    "bin") echo " bin" ;;
    "python") echo " python" ;;
    "Documents"|"documents") echo "󰈙 $carpeta" ;;
    "Downloads"|"downloads") echo " $carpeta" ;;
    "Music"|"music") echo " $carpeta" ;;
    "Pictures"|"pictures") echo " $carpeta" ;;
    "Github"|"github") echo " $carpeta" ;;
    "storage") echo " storage" ;;
    
    # EL ICONO POR DEFECTO PARA TODO LO DEMÁS (como cava)
    *) echo " $carpeta" ;;
esac
