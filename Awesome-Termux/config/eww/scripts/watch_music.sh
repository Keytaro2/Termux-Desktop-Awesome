#!/data/data/com.termux/files/usr/bin/bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

LAST_TITLE=""

while true; do
    # We get the lyrics to Audacious's current song
    CURRENT_TITLE="$(audtool --current-song 2>/dev/null)"

    if [ -n "$CURRENT_TITLE" ] && [ "$CURRENT_TITLE" != "$LAST_TITLE" ]; then

        # 1. We tried to extract title and artist directly from the internal metadata
        SONG_TITLE=$(audtool current-song-tuple-data title 2>/dev/null)
        SONG_ARTIST=$(audtool current-song-tuple-data artist 2>/dev/null)

        # 2. SMART SEPARATION: If the metadata is empty or duplicated
        if [ -z "$SONG_TITLE" ] || [ "$SONG_TITLE" = "$SONG_ARTIST" ]; then
            if [[ "$CURRENT_TITLE" == *" - "* ]]; then
                SONG_ARTIST="${CURRENT_TITLE%% - *}"
                SONG_TITLE="${CURRENT_TITLE#* - }"
            else
                SONG_TITLE="$CURRENT_TITLE"
                SONG_ARTIST="Audio Player"
            fi
        fi

        # 3. We extract the cover using the ABSOLUTE PATH
        FRONT_PAGE=$(bash /data/data/com.termux/files/home/.config/eww/scripts/cover.sh)

        # 4. We send to the panel using the ABSOLUTE PATH
        bash /data/data/com.termux/files/home/.config/eww/scripts/logger.sh "Music" "$SONG_TITLE" "$SONG_ARTIST" "$FRONT_PAGE"

        LAST_TITLE="$CURRENT_TITLE"
    fi

    sleep 2
done
