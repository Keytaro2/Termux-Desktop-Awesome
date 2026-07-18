#!/bin/bash

# Get the current microphone volume (cut off the output to get only the number)
get_mic_vol() {
    pactl get-source-volume @DEFAULT_SOURCE@ | grep -Po '\d+(?=%)' | head -n 1
}

# Set microphone volume
set_mic_vol() {
    pactl set-source-volume @DEFAULT_SOURCE@ "$1%"
}

# If no number is passed, Eww will use the script to check the status
if [ -z "$1" ]; then
    get_mic_vol
# If Eww sends a number (when you move the slider), adjust the volume
else
    set_mic_vol "$1"
fi
