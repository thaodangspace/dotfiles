#!/bin/bash

# Debug function
# Get current workspace name
CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)

GHOSTTY_ON_CURRENT=$(aerospace list-windows --app-bundle-id org.qutebrowser.qutebrowser --workspace focused --count)

if [ -z "$GHOSTTY_ON_CURRENT" ]; then
    GHOSTTY_ON_CURRENT=0
fi

if [ "$GHOSTTY_ON_CURRENT" -gt 0 ]; then
    WINDOW_ID=$(aerospace list-windows --app-bundle-id org.qutebrowser.qutebrowser --workspace focused --format "%{window-id}" | head -n1)
    # aerospace macos-native-minimize --window-id "$WINDOW_ID"
    #move node to workspace 3.Terminal
    aerospace move-node-to-workspace "6.Space" --window-id "$WINDOW_ID"
else
    GHOSTTY_TOTAL=$(aerospace list-windows --app-bundle-id org.qutebrowser.qutebrowser --monitor all --count)

    if [ -z "$GHOSTTY_TOTAL" ]; then
        GHOSTTY_TOTAL=0
    fi

    if [ "$GHOSTTY_TOTAL" -gt 0 ]; then
        WINDOW_ID=$(aerospace list-windows --app-bundle-id org.qutebrowser.qutebrowser --monitor all --format "%{window-id}" | head -n1)
        debug "Window ID to move: $WINDOW_ID"

        aerospace move-node-to-workspace "$CURRENT_WORKSPACE" --window-id "$WINDOW_ID"

        aerospace layout floating --window-id "$WINDOW_ID"

        aerospace focus --window-id "$WINDOW_ID"

    else
        open -a Ghostty
    fi
fi
