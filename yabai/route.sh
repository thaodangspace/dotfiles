#!/usr/bin/env bash
# route.sh <window-id> [default-space] [--follow]
#
# Called from the window_created signal in yabairc (and once per existing
# window at startup). Windows of apps that have NO per-app rule in yabairc
# (e.g. VS Code) are moved to <default-space> (default 5) instead of landing
# on whatever space happens to be focused. With --follow, focus jumps to the
# moved window (the signal passes it; the startup pass does not, so a yabai
# restart never yanks you to that space).
#
# The per-app rules in yabairc stay the single source of truth: this script
# reads them back with `yabai -m rule --list`, so the app list is not
# duplicated here. An app counts as "configured" when any rule with an
# app= regex other than the ".*" catch-all (float-default) matches its name.
#
# Moving a window to another space works with or without the scripting
# addition; following it is delegated to focus-space.sh.
set -u
wid="${1:?usage: route.sh <window-id> [default-space] [--follow]}"
default_space="${2:-5}"
follow=0; [ "${3:-}" = "--follow" ] && follow=1

# Window may already be gone (short-lived popups) -> nothing to do.
info=$(yabai -m query --windows --window "$wid" 2>/dev/null) || exit 0
app=$(jq -r '.app // empty' <<<"$info")
[ -z "$app" ] && exit 0

# Only route real top-level windows; leave dialogs, sheets and popups alone.
[ "$(jq -r '.subrole // empty' <<<"$info")" = "AXStandardWindow" ] || exit 0

# Configured app? -> some app= rule (other than ".*") matches this app name.
matched=$(yabai -m rule --list | jq --arg app "$app" '
  [ .[] | (.app // "") as $re
        | select($re != "" and $re != ".*")
        | select($app | test($re)) ] | length')
[ "${matched:-0}" -gt 0 ] && exit 0

# Target space must exist (yabai cannot create spaces with SIP on).
target=$(yabai -m query --spaces --space "$default_space" 2>/dev/null | jq -r '.index // empty')
if [ -z "$target" ]; then
  echo "route.sh: space $default_space does not exist, '$app' left where it is (create the space in Mission Control)" >&2
  exit 1
fi

current=$(jq -r '.space' <<<"$info")
if [ "$current" != "$target" ]; then
  yabai -m window "$wid" --space "$target" || exit 1
fi

[ "$follow" = 1 ] || exit 0

# Follow the window: switch space first (focus-space.sh uses the scripting
# addition when it works, animated fallbacks otherwise), then focus the window.
~/.config/yabai/focus-space.sh "$target"
yabai -m window --focus "$wid" 2>/dev/null || true
