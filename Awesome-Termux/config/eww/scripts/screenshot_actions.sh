#!/bin/bash
ACTION="$1"
IMG_PATH="$2"
JSON_FILE="/data/data/com.termux/files/usr/tmp/notifs.json"
PIPE_FILE="/data/data/com.termux/files/usr/tmp/notifs.pipe"

if [ "$ACTION" == "copy" ]; then
    # 1. Actual command to copy to clipboard (Uncomment and adjust if you have termux-api or xclip configured)
    # termux-clipboard-set "$IMG_PATH" 

    # 2. Generate a unique ID based on time
    NEW_ID=$(date +%s)

    # 3. Add the copy notification AT THE BEGINNING of the JSON
    jq "[{\"id\": \"$NEW_ID\", \"app\": \"Screenshot\", \"title\": \"Screenshot\", \"body\": \"Screenshot copied successfully.\", \"image\": \"\"}] + ." "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"

    # 4. Notify Eww to refresh the panel list
    echo "update" >> "$PIPE_FILE"

    # 5. Close the normal popup and open the successful copy popup
    eww close popup_screenshot -c ~/.config/eww/notifications
    eww open popup_screenshot_copied -c ~/.config/eww/notifications
    sleep 3
    eww close popup_screenshot_copied -c ~/.config/eww/notifications

elif [ "$ACTION" == "delete" ]; then
    # 1. Delete the physical image file (optional, if it was only visual you can delete or comment this line)
#    rm -f "$IMG_PATH"

    # 2. Generate a unique ID based on time
    NEW_ID=$(date +%s)

    # 3. Add the "text-only" notification AT THE BEGINNING of the JSON (so it appears at the top)
    jq "[{\"id\": \"$NEW_ID\", \"app\": \"Screenshot\", \"title\": \"Screenshot\", \"body\": \"Screenshot removed successfully.\", \"image\": \"\"}] + ." "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"

    # 4. Notify Eww to refresh the list
    echo "update" >> "$PIPE_FILE"

    # 5. Show the floating deletion popup
    eww close popup_screenshot -c ~/.config/eww/notifications
    eww open popup_screenshot_deleted -c ~/.config/eww/notifications
    sleep 3
    eww close popup_screenshot_deleted -c ~/.config/eww/notifications
fi
