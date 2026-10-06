#!/bin/bash
state=$(eww get open_screenshot)

case $1 in
    close)
        eww update open_screenshot=false
        eww close screenshot
        eww close screenshot-closer
        exit 0
        ;;
esac

case $state in
    true)
        eww update open_screenshot=false
        eww close screenshot
        eww close screenshot-closer
        ;;
    false)
        eww update open_screenshot=true
        eww open screenshot-closer
        eww open screenshot &
        ;;
esac
