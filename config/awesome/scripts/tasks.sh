#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

# Rendering function
generate_bar() {
    # 1. Obtain the ID of the active window directly from the root window
    # We use awk to clean up formatting: "_NET_ACTIVE_WINDOW(WINDOW): window id # 0x60000a" -> "0x60000a"
    ACTIVE_WIN=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $5}')
    
    # 2. Get window list (ignore root)
    CLIENT_LIST=$(xprop -root _NET_CLIENT_LIST | sed 's/.*# //; s/,//g')

    RESULT="(box :orientation \"v\" :space-evenly false :spacing 10 "

    # 3. Iterate over the window IDs
    for win_id in $CLIENT_LIST; do
        # Verify class name to filter (avoid Eww and other internals)
        WM_CLASS=$(xprop -id "$win_id" WM_CLASS 2>/dev/null | cut -d'"' -f2)
        
        if [[ "$WM_CLASS" == "eww" || "$WM_CLASS" == "" ]]; then
            continue
        fi

        # 4. Style logic (Same as in your tint2)
        if [ "$win_id" == "$ACTIVE_WIN" ]; then
            # ACTIVATE (Highlighted Blue)
            STYLE="background-color: #7da6ff; min-height: 24px; min-width: 8px; border-radius: 6px;"
        else
            # INACTIVE (Light Blue/Gray)
            STYLE="background-color: #7da6ff; opacity: 0.39; min-height: 8px; min-width: 8px; border-radius: 6px;"
        fi

        RESULT+="(button :onclick \"xdotool windowactivate $win_id\" :style \"$STYLE\" \"\") "
    done

    RESULT+=")"
    echo "$RESULT"
}

# 5. Actual event loop (this is what keeps the bar alive)
# It waits for the active window to change
xprop -root -spy _NET_ACTIVE_WINDOW _NET_CLIENT_LIST | while read -r line; do
    generate_bar
done
