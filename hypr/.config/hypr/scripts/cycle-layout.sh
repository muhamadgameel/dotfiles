#!/bin/bash
LAYOUTS=("dwindle" "master" "scrolling")
CURRENT=$(hyprctl -j getoption general:layout | jq -r '.str')

for i in "${!LAYOUTS[@]}"; do
    if [[ "${LAYOUTS[$i]}" == "$CURRENT" ]]; then
        NEXT=$(( (i + 1) % ${#LAYOUTS[@]} ))
        hyprctl keyword general:layout "${LAYOUTS[$NEXT]}"
        notify-send -t 1500 -h string:x-canonical-private-synchronous:layout \
            "Layout" "${LAYOUTS[$NEXT]}"
        exit 0
    fi
done

hyprctl keyword general:layout "${LAYOUTS[0]}"
notify-send -t 1500 -h string:x-canonical-private-synchronous:layout \
    "Layout" "${LAYOUTS[0]}"
