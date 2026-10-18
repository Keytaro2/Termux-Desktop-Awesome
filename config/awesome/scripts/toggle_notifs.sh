#!/bin/bash

# Check if the "notifications" window is open in the notifications folder
if eww -c ~/.config/eww/notifications active-windows | grep -q "notifications"; then
    # If it's open, close it and turn off the icon in menu2
    eww -c ~/.config/eww/notifications close notifications
    eww -c ~/.config/eww/menu2 update show_notif=false
else
    # If it's closed, open it and turn on the icon in menu2
    eww -c ~/.config/eww/notifications open notifications
    eww -c ~/.config/eww/menu2 update show_notif=true
fi
