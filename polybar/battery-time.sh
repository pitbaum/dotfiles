#!/bin/bash

format_time() {
    local t="$1"
    t="$(echo "$t" | sed 's/^[ \t]*//;s/[ \t]*$//')"

    # Match H:M or H:M:S
    if [[ "$t" =~ ^([0-9]+):([0-9]{2})(:[0-9]{2})?$ ]]; then
        local h="${BASH_REMATCH[1]}"
        local m="${BASH_REMATCH[2]}"
        printf "%02d:%02d:00\n" "$h" "$m"
        return
    fi

    # Match decimal hours like "6.7 hours"
    if [[ "$t" =~ ^([0-9]+)\.([0-9]+)[[:space:]]*hours?$ ]]; then
        local h="${BASH_REMATCH[1]}"
        local dec="0.${BASH_REMATCH[2]}"
        local m=$(printf "%.0f" "$(echo "$dec * 60" | bc -l)")
        # If minutes = 60, increment hour and set minutes to 0
        if [ "$m" -eq 60 ]; then
            m=0
            h=$((h + 1))
        fi
        printf "%02d:%02d:00\n" "$h" "$m"
        return
    fi

    # Match minutes only like "30 minutes"
    if [[ "$t" =~ ^([0-9]+)[[:space:]]*minutes?$ ]]; then
        local m="${BASH_REMATCH[1]}"
        printf "00:%02d:00\n" "$m"
        return
    fi

    # Fallback: print original string
    echo "$t"
}

BAT=$(upower -e | grep BAT)
if [ -z "$BAT" ]; then
    echo "No battery"
    exit 0
fi

STATE=$(upower -i "$BAT" | awk '/state:/ {print $2}')
PERCENT=$(upower -i "$BAT" | awk '/percentage:/ {print $2}')
TIME_RAW=$(upower -i "$BAT" | awk -F': +' '/time to/ {print $2}')

TIME_FMT=$(format_time "$TIME_RAW")

ORANGE="%{F#F0C674}"
RESET="%{F-}"

if [ "$STATE" = "discharging" ]; then
    echo "${ORANGE}BAT${RESET} ${PERCENT} (${ORANGE}${TIME_FMT}${RESET})"
elif [ "$STATE" = "charging" ]; then
    echo "${ORANGE}AC${RESET} ${PERCENT} (${ORANGE}${TIME_FMT}${RESET})"
else
    echo "${PERCENT}"
fi
