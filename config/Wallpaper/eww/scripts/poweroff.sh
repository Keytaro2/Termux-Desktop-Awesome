#!/bin/bash

# Capture the argument sent by Eww (logout, reboot, poweroff)
ACTION="$1"

case "$ACTION" in
    "logout")
        # Close Awesome WM cleanly
        pkill -x awesome
        ;;

    "reboot")
        # Close the current Awesome instance to avoid conflicts and launch the startup script in the background
        pkill -9 awesome
        ~/startawesome_termux.sh &
        ;;

    "poweroff")
        # Close the entire graphical environment in Termux-X11
        pkill -9 awesome
        pkill -9 termux-x11
        ;;

    *)
        echo "Correct use: $0 {logout|reboot|poweroff}"
        exit 1
        ;;
esac

