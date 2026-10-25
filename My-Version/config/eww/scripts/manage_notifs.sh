#!/bin/bash
JSON_FILE="/data/data/com.termux/files/usr/tmp/notifs.json"
PIPE_FILE="/data/data/com.termux/files/usr/tmp/notifs.pipe"

if [ "$1" == "--delete" ]; then
    jq "del(.[] | select(.id == \"$2\"))" "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"
    echo "update" >> "$PIPE_FILE"
fi
