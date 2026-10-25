#!/data/data/com.termux/files/usr/bin/bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

# Routes for Termux
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

# --- LOGIC ---
if [ "$ICON" == "null" ]; then
    IMAGE=""
elif [ -f "$ICON" ]; then
    IMAGE="$ICON"
elif [[ "$SUMMARY" == *"Screenshot"* || "$BODY" == *"Screenshot"* ]]; then
    IMAGE=$(ls -t /data/data/com.termux/files/home/storage/dcim/Screenshots/*.jpg 2>/dev/null | head -n 1)
fi
# ------------------------

NEW_NOTIF=$(jq -n \
  --arg id "$ID" \
  --arg app "$APP_NAME" \
  --arg title "$SUMMARY" \
  --arg body "$BODY" \
  --arg img "$IMAGE" \
  '{id: $id, app: $app, title: $title, body: $body, image: $img}')

jq ". = [$NEW_NOTIF] + ." "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"

echo "update" >> "$PIPE_FILE"
