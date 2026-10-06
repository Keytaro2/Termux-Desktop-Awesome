#!/data/data/com.termux/files/usr/bin/bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

JSON_FILE="/data/data/com.termux/files/usr/tmp/notifs.json"
PIPE_FILE="/data/data/com.termux/files/usr/tmp/notifs.pipe"

if [ ! -s "$JSON_FILE" ]; then
    echo "[]" > "$JSON_FILE"
fi

APP_NAME="$1"
SUMMARY="$2"
BODY="$3"
ICON="$4"
ID=$(date +%s%N | cut -b1-13)
IMAGE=""

# Variable to detect if it's a deletion notification
IS_REMOVE=0
if [[ "${SUMMARY,,}" == *"remove"* || "${BODY,,}" == *"remove"* || "${SUMMARY,,}" == *"delete"* || "${BODY,,}" == *"delete"* ]]; then
    IS_REMOVE=1
fi

# Detect image (png/jpg files in downloads or dcim/Screenshots or absolute path)
if [ -f "$ICON" ]; then
    IMAGE="$ICON"
elif [[ "$SUMMARY" == *"Screenshot"* || "$BODY" == *"Screenshot"* || "$APP_NAME" == *"Screenshot"* ]]; then
    if [ "$IS_REMOVE" -eq 0 ]; then
        sleep 0.3
        IMAGE=$(ls -t /data/data/com.termux/files/home/storage/downloads/*.png \
                      /data/data/com.termux/files/home/storage/downloads/*.jpg \
                      /data/data/com.termux/files/home/storage/dcim/Screenshots/*.png \
                      /data/data/com.termux/files/home/storage/dcim/Screenshots/*.jpg 2>/dev/null | head -n 1)
    fi
fi

# ==========================================
# Floating screenshot popup logic
# ==========================================
if [[ "$SUMMARY" == *"Screenshot"* || "$BODY" == *"Screenshot"* || "$APP_NAME" == *"Screenshot"* ]]; then
    if [ -n "$IMAGE" ] && [ "$IS_REMOVE" -eq 0 ]; then
        (
            eww -c ~/.config/eww/notifications close popup_screenshot 2>/dev/null
            sleep 0.1
            eww -c ~/.config/eww/notifications update current_screenshot="$IMAGE"
            eww -c ~/.config/eww/notifications open popup_screenshot
            sleep 5
            eww -c ~/.config/eww/notifications close popup_screenshot
        ) &
    fi
fi

# ==========================================
# Floating music popup logic
# ==========================================
if [[ "$APP_NAME" == "Music" || "$APP_NAME" == "Audacious" ]]; then
    (
        eww -c ~/.config/eww/notifications close popup_music 2>/dev/null
        sleep 0.1
        if [ -n "$IMAGE" ]; then
            eww -c ~/.config/eww/notifications update audacious_cover="$IMAGE"
        fi
        eww -c ~/.config/eww/notifications open popup_music
        sleep 5
        eww -c ~/.config/eww/notifications close popup_music
    ) &
fi

# ==========================================
# Floating Launchers popup logic
# ==========================================
if [[ "$APP_NAME" == "Launchers" ]]; then
    if [[ "$BODY" == *"terminal"* ]]; then
        (
            eww -c ~/.config/eww/notifications close popup_launcher 2>/dev/null
            sleep 0.1
            eww -c ~/.config/eww/notifications open popup_launcher
            sleep 3
            eww -c ~/.config/eww/notifications close popup_launcher
        ) &
    elif [[ "$BODY" == *"explorer"* ]]; then
        (
            eww -c ~/.config/eww/notifications close popup_explorer 2>/dev/null
            sleep 0.1
            eww -c ~/.config/eww/notifications open popup_explorer
            sleep 3
            eww -c ~/.config/eww/notifications close popup_explorer
        ) &
    elif [[ "$BODY" == *"browser"* ]]; then
        (
            eww -c ~/.config/eww/notifications close popup_browser 2>/dev/null
            sleep 0.1
            eww -c ~/.config/eww/notifications open popup_browser
            sleep 3
            eww -c ~/.config/eww/notifications close popup_browser
        ) &
    fi
fi

# ==========================================
# Write to JSON and notify Eww
# ==========================================
NEW_NOTIF=$(jq -n \
  --arg id "$ID" \
  --arg app "$APP_NAME" \
  --arg title "$SUMMARY" \
  --arg body "$BODY" \
  --arg img "$IMAGE" \
  '{id: $id, app: $app, title: $title, body: $body, image: $img}')

jq ". = [$NEW_NOTIF] + ." "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"

echo "update" >> "$PIPE_FILE"
