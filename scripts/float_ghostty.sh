#!/bin/bash

# Debug function
debug() {
    echo "DEBUG: $1" >> /tmp/aerospace_toggle_debug.log
}

debug "=== Toggle Ghostty Script Started ==="

# Get current workspace name
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)
debug "Current workspace: $CURRENT_WORKSPACE"

GHOSTTY_ON_CURRENT=$(aerospace list-windows --app-bundle-id com.mitchellh.ghostty --workspace focused --count)
debug "Ghostty windows on current workspace: $GHOSTTY_ON_CURRENT"

if [ -z "$GHOSTTY_ON_CURRENT" ]; then
    GHOSTTY_ON_CURRENT=0
fi

if [ "$GHOSTTY_ON_CURRENT" -gt 0 ]; then
    debug "Ghostty found on current workspace, minimizing..."
    WINDOW_ID=$(aerospace list-windows --app-bundle-id com.mitchellh.ghostty --workspace focused --format "%{window-id}" | head -n1)
    debug "Window ID to minimize: $WINDOW_ID"
    # aerospace macos-native-minimize --window-id "$WINDOW_ID"
    #move node to workspace 3.Terminal
    aerospace move-node-to-workspace "3.Terminal" --window-id "$WINDOW_ID"
else
    debug "Ghostty not on current workspace, checking if it exists elsewhere..."
    GHOSTTY_TOTAL=$(aerospace list-windows --app-bundle-id com.mitchellh.ghostty --monitor all --count)
    debug "Total Ghostty windows: $GHOSTTY_TOTAL"
    
    if [ -z "$GHOSTTY_TOTAL" ]; then
        GHOSTTY_TOTAL=0
    fi
    
    if [ "$GHOSTTY_TOTAL" -gt 0 ]; then
        debug "Ghostty exists elsewhere, moving to current workspace..."
        WINDOW_ID=$(aerospace list-windows --app-bundle-id com.mitchellh.ghostty --monitor all --format "%{window-id}" | head -n1)
        debug "Window ID to move: $WINDOW_ID"
        
        aerospace move-node-to-workspace "$CURRENT_WORKSPACE" --window-id "$WINDOW_ID"
        
        aerospace layout floating --window-id "$WINDOW_ID"
        
        aerospace focus --window-id "$WINDOW_ID"
        
        debug "Moved Ghostty window $WINDOW_ID to workspace $CURRENT_WORKSPACE"
    else
        debug "Ghostty not running, opening new instance..."
        open -a Ghostty
    fi
fi

debug "=== Toggle Ghostty Script Completed ===" 