#!/data/data/com.termux/files/usr/bin/bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

CACHE_DIR="$HOME/.cache/eww/covers"
DEFAULT_IMG="$HOME/.config/awesome/assets/music.png"
[ -f "$DEFAULT_IMG" ] || DEFAULT_IMG="$HOME/.config/eww/assets/music.png"

mkdir -p "$CACHE_DIR"

raw_path=$(audtool current-song-filename 2>/dev/null)
if [[ -z "$raw_path" ]]; then
    echo "$DEFAULT_IMG"; exit 0
fi

real_path="${raw_path#file://}"
real_path=$(printf '%b' "${real_path//%/\\x}")

if [[ "$real_path" == http* ]]; then
    echo "$DEFAULT_IMG"; exit 0
fi

HASH=$(echo -n "$real_path" | md5sum | awk '{print $1}')
COVER_PATH="$CACHE_DIR/${HASH}.jpg"

if [[ -f "$COVER_PATH" ]]; then
    echo "$COVER_PATH"; exit 0
fi

if [[ -f "$real_path" ]]; then
    ffmpeg -y -i "$real_path" -an -vframes 1 -update 1 -c:v mjpeg "$COVER_PATH" > /dev/null 2>&1
    if [[ $? -eq 0 && -f "$COVER_PATH" ]]; then
        echo "$COVER_PATH"; exit 0
    fi
fi

echo "$DEFAULT_IMG"
