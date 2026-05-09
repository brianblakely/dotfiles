#!/bin/bash

# Duration to display waybar (in seconds)
DISPLAY_DURATION=1.5

# Check if waybar is already running
if ! pgrep -x waybar >/dev/null; then
  # Start waybar in the background
  uwsm-app -- waybar >/dev/null 2>&1 &
fi

# Wait for the specified duration
sleep "$DISPLAY_DURATION"

# Kill waybar
pkill -x waybar
