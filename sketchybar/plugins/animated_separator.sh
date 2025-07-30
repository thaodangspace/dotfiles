#!/bin/bash

# Animated separator for sketchybar
# Cycles through different separator characters

# Array of separator characters for animation
SEPARATORS=(
  "│"    # Vertical line
  "┃"    # Heavy vertical line  
  "║"    # Double vertical line
  "▌"    # Left half block
  "▐"    # Right half block
  "█"    # Full block
  "▐"    # Right half block
  "▌"    # Left half block
  "║"    # Double vertical line
  "┃"    # Heavy vertical line
)

# Alternative dot-based animation
DOT_SEPARATORS=(
  "·"    # Middle dot
  "•"    # Bullet
  "●"    # Black circle
  "◆"    # Black diamond
  "◇"    # White diamond
  "◆"    # Black diamond
  "●"    # Black circle
  "•"    # Bullet
)

# Alternative wave-based animation
WAVE_SEPARATORS=(
  "~"    # Tilde
  "∼"    # Tilde operator
  "≈"    # Almost equal
  "∿"    # Sine wave
  "≈"    # Almost equal
  "∼"    # Tilde operator
)

SHAPER_SEPARATORS=(
  "⠋"
  "⠙"
  "⠹"
  "⠸"
  "⠼"
  "⠴"
  "⠦"
)

WEATHER_SEPARATORS=(
  "☀️ "
  "☀️ "
  "☀️ "
  "🌤 "
  "⛅️ "
  "🌥 "
  "☁️ "
  "🌧 "
  "🌨 "
  "🌧 "
  "🌨 "
  "🌧 "
	"🌨 "
  "⛈ "
  "🌨 "
  "🌧 "
  "🌨 "
  "☁️ "
  "🌥 "
  "⛅️ "
  "🌤 "
  "☀️ "
  "☀️ "
)
# Get the current animation style (you can change this)
ANIMATION_STYLE=${ANIMATION_STYLE:-"shaper"}  # options: bars, dots, waves, shaper, weather

case "$ANIMATION_STYLE" in
  "dots")
    ICONS=("${DOT_SEPARATORS[@]}")
    ;;
  "waves") 
    ICONS=("${WAVE_SEPARATORS[@]}")
    ;;
  "shaper")
    ICONS=("${SHAPER_SEPARATORS[@]}")
    ;;
  "weather")
    ICONS=("${WEATHER_SEPARATORS[@]}")
    ;;
  *)
    ICONS=("${SEPARATORS[@]}")
    ;;
esac

# Get current timestamp to determine animation frame
CURRENT_TIME=$(date +%s)
FRAME_COUNT=${#ICONS[@]}
CURRENT_FRAME=$((CURRENT_TIME % FRAME_COUNT))

# Get the current icon
CURRENT_ICON="${ICONS[$CURRENT_FRAME]}"

# Update the separator
sketchybar --set space_separator icon="$CURRENT_ICON"

# Schedule next update (optional - for smoother animation)
if [ "$1" = "continuous" ]; then
  sleep 0.5
  exec "$0" continuous
fi 