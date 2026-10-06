#!/bin/bash
JSON_FILE="/data/data/com.termux/files/usr/tmp/notifs.json"
PIPE_FILE="/data/data/com.termux/files/usr/tmp/notifs.pipe"

if [ "$1" == "--delete" ]; then
    # 1. Change the app name to "removed" so Eww shows your design
    jq 'map(if .id == "'"$2"'" then .app = "removed" else . end)' "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"
    echo "update" >> "$PIPE_FILE"

    # 2. Pause for 2.5 seconds so you can see the message
    sleep 2.5

    # 3. Now, definitively remove the notification from the log
    jq 'del(.[] | select(.id == "'"$2"'"))' "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"
    echo "update" >> "$PIPE_FILE"
fi
