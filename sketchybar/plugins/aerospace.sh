#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

# Define an array of random background colors for focused workspace
COLORS=(
  "0xffe74c3c"  # Red
  "0xff3498db"  # Blue
  "0xff2ecc71"  # Green
  "0xfff39c12"  # Orange
  "0xff9b59b6"  # Purple
  "0xff1abc9c"  # Teal
  "0xffe67e22"  # Dark orange
  "0xff34495e"  # Dark blue-gray
  "0xfff1c40f"  # Yellow
  "0xffe91e63"  # Pink
  "0xff95a5a6"  # Gray
  "0xfffd79a8"  # Light pink
)

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.color=0xFF011627 background.border_width=1
else
  sketchybar --set $NAME background.color=0x00RRGGBB background.border_width=0
fi