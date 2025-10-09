#!/bin/bash

# brew install media-control
# Get media info using media-control
update_video_info() {
  # Get current media state as JSON
  MEDIA_JSON=$(media-control get 2>/dev/null)

  # Check if we got valid JSON output
  if [ -z "$MEDIA_JSON" ] || [ "$MEDIA_JSON" = "null" ]; then
    sketchybar --set $NAME drawing=off
    return
  fi

  # Parse JSON using jq (or fallback to grep/sed if jq not available)
  if command -v jq &> /dev/null; then
    IS_PLAYING=$(echo "$MEDIA_JSON" | jq -r '.playing // false')
    TITLE=$(echo "$MEDIA_JSON" | jq -r '.title // ""')
    ARTIST=$(echo "$MEDIA_JSON" | jq -r '.artist // ""')
  else
    # Fallback parsing without jq
    IS_PLAYING=$(echo "$MEDIA_JSON" | grep -o '"playing":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    TITLE=$(echo "$MEDIA_JSON" | grep -o '"title":"[^"]*"' | cut -d'"' -f4)
    ARTIST=$(echo "$MEDIA_JSON" | grep -o '"artist":"[^"]*"' | cut -d'"' -f4)
  fi

  # Build display text
  if [ "$IS_PLAYING" = "true" ]; then
    # Combine title and artist if both exist
    if [ -n "$TITLE" ] && [ -n "$ARTIST" ]; then
      DISPLAY_TEXT="$TITLE - $ARTIST"
    elif [ -n "$TITLE" ]; then
      DISPLAY_TEXT="$TITLE"
    else
      DISPLAY_TEXT="Playing"
    fi

    # Set icon to pause since media is playing
    ICON=""
  else
    DISPLAY_TEXT=""
    ICON=""
  fi

  # Truncate text if too long
  if [ ${#DISPLAY_TEXT} -gt 30 ]; then
    DISPLAY_TEXT="${DISPLAY_TEXT:0:27}..."
  fi

  # If no media is playing, show nothing
  if [ -z "$DISPLAY_TEXT" ]; then
    sketchybar --set $NAME drawing=off
  else
    sketchybar --set $NAME drawing=on icon="$ICON" label="$DISPLAY_TEXT"
  fi
}

# Toggle play/pause using media-control
toggle_play_pause() {
  media-control toggle-play-pause
}

case "$SENDER" in
  "mouse.clicked") toggle_play_pause
    ;;
  *) update_video_info
    ;;
esac
