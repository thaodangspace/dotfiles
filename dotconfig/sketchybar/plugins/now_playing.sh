#!/bin/bash

# Get media info from macOS Media Remote framework
update_video_info() {
  # Get current playing state
  IS_PLAYING=$(nowplaying-cli get playbackRate)
  if [ "$IS_PLAYING" = "1" ]; then
    # Get media title and app name
    TITLE=$(nowplaying-cli get title)
    APP_NAME=$(nowplaying-cli get application)
    
    # If title is empty but we have an app name, use app name
    if [ -z "$TITLE" ] && [ -n "$APP_NAME" ]; then
      TITLE="Playing in $APP_NAME"
    fi
    
    # Set icon to pause since media is playing
    ICON=""
  else
    TITLE=""
    ICON=""
  fi

  # Truncate title if too long
  if [ ${#TITLE} -gt 30 ]; then
    TITLE="${TITLE:0:27}..."
  fi

  # If no media is playing, show nothing
  if [ -z "$TITLE" ]; then
    sketchybar --set $NAME drawing=off
  else
    sketchybar --set $NAME drawing=on icon="$ICON" label="$TITLE"
  fi
}

# Toggle play/pause using system media control
toggle_play_pause() {
  nowplaying-cli toggle
}

case "$SENDER" in
  "mouse.clicked") toggle_play_pause
    ;;
  *) update_video_info
    ;;
esac 