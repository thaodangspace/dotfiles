#!/usr/bin/env bash
# Floating tmux "window manager": fuzzy-pick any window across all sessions
# and switch to it. Windows are grouped under their session (tree-style) with a
# live preview of the window's active pane. Launched from a popup (prefix + w).
set -euo pipefail

# Launched via `run-shell -b` so the switch happens AFTER the popup closes —
# running switch-client from inside a popup gets undone when the popup closes.
# run-shell uses tmux's server env, so make sure Homebrew bins are on PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Client that invoked the keybinding (passed in), so we switch the right one.
client="${1:-}"

cyan=$'\033[1;36m'; grn=$'\033[32m'; dim=$'\033[2m'; rst=$'\033[0m'

# Each emitted line is: <target>\t<display>
#   target  = "session:window_index" for windows, or "session" for header rows
#   display = colored, indented label shown by fzf (--with-nth=2)
# Header rows carry the session as target so searching/selecting a session name
# switches to that session's current window (window rows don't repeat the name).
build() {
  local prev=""
  while IFS=$'\t' read -r sess idx active name cmd; do
    if [ "$sess" != "$prev" ]; then
      printf '%s\t%s%s%s\n' "$sess" "$cyan" "$sess" "$rst"   # session header
      prev="$sess"
    fi
    local dot="  "
    [ "$active" = "1" ] && dot="${grn}●${rst} "
    printf '%s:%s\t   %s%s%s:%s %s %s(%s)%s\n' \
      "$sess" "$idx" "$dot" "$dim" "$idx" "$rst" "$name" "$dim" "$cmd" "$rst"
  done < <(
    tmux list-windows -a \
      -F '#{session_name}	#{window_index}	#{window_active}	#{window_name}	#{pane_current_command}' \
    | sort -t$'\t' -k1,1 -k2,2n
  )
}

sel="$(
  build | fzf --tmux center,85%,75% \
      --ansi --reverse --no-sort --prompt='window > ' \
      --delimiter=$'\t' --with-nth=2 \
      --preview='tmux capture-pane -ep -t {1} 2>/dev/null' \
      --preview-window='right,60%,wrap' \
      --border --header='switch to window'
)" || exit 0

target="${sel%%$'\t'*}"
[ -n "$target" ] || exit 0

# Build the switch-client args, targeting the launching client when known.
set --
[ -n "$client" ] && set -- -c "$client"

if [[ "$target" == *:* ]]; then
  # window row: switch to its session, then select the window
  tmux switch-client "$@" -t "${target%:*}" \; select-window -t "$target"
else
  # header row: switch to the session's current window
  tmux switch-client "$@" -t "$target"
fi
