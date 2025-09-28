#!/bin/bash

# Get current workspace name
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)

FIREFOX_ON_CURRENT=$(aerospace list-windows --app-bundle-id org.mozilla.firefoxdeveloperedition --workspace focused --count)

if [ -z "$FIREFOX_ON_CURRENT" ]; then
  FIREFOX_ON_CURRENT=0
fi

if [ "$FIREFOX_ON_CURRENT" -gt 0 ]; then
  # Firefox is on current workspace, move it to workspace 6
  WINDOW_ID=$(aerospace list-windows --app-bundle-id org.mozilla.firefoxdeveloperedition --workspace focused --format "%{window-id}" | head -n1)
  aerospace move-node-to-workspace 6 --window-id "$WINDOW_ID"
else
  # Check if Firefox is on workspace 6
  FIREFOX_ON_6=$(aerospace list-windows --app-bundle-id org.mozilla.firefoxdeveloperedition --workspace 6 --count)

  if [ -z "$FIREFOX_ON_6" ]; then
    FIREFOX_ON_6=0
  fi

  if [ "$FIREFOX_ON_6" -gt 0 ]; then
    # Firefox is on workspace 6, move it to current workspace
    WINDOW_ID=$(aerospace list-windows --app-bundle-id org.mozilla.firefoxdeveloperedition --workspace 6 --format "%{window-id}" | head -n1)
    aerospace move-node-to-workspace "$CURRENT_WORKSPACE" --window-id "$WINDOW_ID"
    aerospace layout floating --window-id "$WINDOW_ID"
    aerospace focus --window-id "$WINDOW_ID"
  else
    # Check if Firefox exists elsewhere
    FIREFOX_TOTAL=$(aerospace list-windows --app-bundle-id org.mozilla.firefoxdeveloperedition --monitor all --count)

    if [ -z "$FIREFOX_TOTAL" ]; then
      FIREFOX_TOTAL=0
    fi

    if [ "$FIREFOX_TOTAL" -gt 0 ]; then
      # Firefox exists on another workspace, move it to current workspace
      WINDOW_ID=$(aerospace list-windows --app-bundle-id org.mozilla.firefoxdeveloperedition --monitor all --format "%{window-id}" | head -n1)
      aerospace move-node-to-workspace "$CURRENT_WORKSPACE" --window-id "$WINDOW_ID"
      aerospace layout floating --window-id "$WINDOW_ID"
      aerospace focus --window-id "$WINDOW_ID"
    else
      # No Firefox window exists, open a new one
      open -a "Firefox Developer Edition"
    fi
  fi
fi
