#!/usr/bin/env bash
# focus-space.sh <N|recent|prev|next>
#
# 1. `yabai -m space --focus N` — instant, no animation, needs the scripting
#    addition. On macOS 27 without a working SA it returns 0 but does nothing,
#    so the result is verified and we fall through.
# 2. focus a window that lives on the target space (works with SIP on, animated)
# 3. empty space: native Mission Control shortcut ctrl-N ("Switch to Desktop N",
#    enabled by enable-desktop-hotkeys.sh) sent through skhd.
set -u
sel="${1:?usage: focus-space.sh <N|recent|prev|next>}"

target=$(yabai -m query --spaces --space "$sel" 2>/dev/null | jq -r '.index // empty')
if [ -z "$target" ]; then
  echo "focus-space: space '$sel' does not exist (create it in Mission Control)" >&2
  exit 1
fi
current=$(yabai -m query --spaces --space | jq -r .index)
[ "$target" = "$current" ] && exit 0

# 1. scripting addition path (instant, no animation)
if yabai -m space --focus "$target" 2>/dev/null; then
  sleep 0.1
  [ "$(yabai -m query --spaces --space | jq -r .index)" = "$target" ] && exit 0
fi

# 2. focus a real window on the target space
wid=$(yabai -m query --windows --space "$target" 2>/dev/null |
  jq -r 'first(.[] | select(."has-ax-reference" and (."is-minimized" | not))) | .id // empty')
if [ -n "$wid" ]; then
  yabai -m window --focus "$wid" 2>/dev/null
  sleep 0.15
  [ "$(yabai -m query --spaces --space | jq -r .index)" = "$target" ] && exit 0
fi

# 3. empty space (or focusing failed): native ctrl-N, only defined for 1..9
if [ "$target" -ge 1 ] && [ "$target" -le 9 ]; then
  skhd -k "ctrl - $target"
  exit 0
fi

exit 1
