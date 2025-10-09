#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

# Define Catppuccin Mocha colors (Rosewater to Text) in ARGB format
COLORS=(
  "0xfff5e0dc" # Rosewater
  "0xfff2cdcd" # Flamingo
  "0xfff5c2e7" # Pink
  "0xffcba6f7" # Mauve
  "0xfff38ba8" # Red
  "0xffeba0ac" # Maroon
  "0xfffab387" # Peach
  "0xfff9e2af" # Yellow
  "0xffa6e3a1" # Green
  "0xff94e2d5" # Teal
  "0xff89dceb" # Sky
  "0xff74c7ec" # Sapphire
  "0xff89b4fa" # Blue
  "0xffb4befe" # Lavender
  "0xffcdd6f4" # Text
)

# Get a deterministic color based on workspace ID
WORKSPACE_ID="$1"
COLOR_INDEX=$(( $(printf "%d" "'${WORKSPACE_ID:0:1}") % ${#COLORS[@]} ))
RANDOM_COLOR="${COLORS[$COLOR_INDEX]}"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.color="$RANDOM_COLOR" background.border_width=1 icon.color=0xff1e1e2e label.color=0xff1e1e2e
else
  sketchybar --set $NAME background.color=0x00RRGGBB background.border_width=0 icon.color="$RANDOM_COLOR" label.color="$RANDOM_COLOR"
fi
