#!/bin/bash

# We use -f to search the entire command line
check_app() {
    if pgrep -i -f "$1" > /dev/null; then echo "true"; else echo "false"; fi
}

term=$(check_app "xfce4-terminal")
thunar=$(check_app "thunar")
firefox=$(check_app "firefox")
audacious=$(check_app "audacious")

eww -c ~/.config/eww/menu2 update \
    show_term=$term \
    show_thunar=$thunar \
    show_firefox=$firefox \
    show_audacious=$audacious
