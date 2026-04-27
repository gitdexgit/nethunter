#!/bin/bash

TARGET_SCRIPT="autoshot.sh"

PIDS=$(pgrep -f "$TARGET_SCRIPT")

if [ -z "$PIDS" ]; then
    # Not running at all — start it
    "$TARGET_SCRIPT" &
    dunstify -i media-playback-start -u low "Autoshot" "▶ Started"
    exit 0
fi

# It's running — check if stopped (T) or active
ALL_STOPPED=true
for PID in $PIDS; do
    STATUS=$(ps -p $PID -o stat=)
    if [[ "$STATUS" != *T* ]]; then
        ALL_STOPPED=false
        break
    fi
done

if $ALL_STOPPED; then
    # Paused → Resume
    for PID in $PIDS; do
        kill -CONT $PID
    done
    dunstify -i media-playback-start -u low "Autoshot" "▶ Resumed"
else
    # Running → Pause
    for PID in $PIDS; do
        STATUS=$(ps -p $PID -o stat=)
        if [[ "$STATUS" != *T* ]]; then
            kill -STOP $PID
        fi
    done
    dunstify -i media-playback-pause -u low "Autoshot" "⏸ Paused"
fi
