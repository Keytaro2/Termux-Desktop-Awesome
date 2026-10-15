#!/bin/bash

# Get the current state of the vol_muted variable from Eww
CURRENT_MUTED=$(eww get vol_muted)

if [ "$CURRENT_MUTED" == "false" ]; then
    # 1. Mute Multimedia volume (Music, videos, etc.)
    cmd audio set-stream-volume 3 0 2>/dev/null || termux-volume music 0 2>/dev/null

    # 2. Put the phone in SILENT MODE (Calls and notifications)
    cmd audio set-ringer-mode 0 2>/dev/null || termux-volume ring 0 2>/dev/null

    # 3. Change icon in Eww
    eww update vol_muted=true
else
    # 1. Restore Multimedia volume (medium level, e.g., 8 out of 15)
    cmd audio set-stream-volume 3 8 2>/dev/null || termux-volume music 8 2>/dev/null

    # 2. Put the phone in NORMAL MODE (With sound)
    cmd audio set-ringer-mode 2 2>/dev/null || termux-volume ring 8 2>/dev/null

    # 3. Change icon in Eww
    eww update vol_muted=false
fi
