#!/usr/bin/env bash
# Floating tmux "window manager": fuzzy-pick any window across all sessions
# and switch to it. Windows are grouped under their session (tree-style) with a
# live preview of the window's active pane. Launched from a popup (prefix + w).
set -euo pipefail

# Launched via `run-shell -b` so the switch happens AFTER the popup closes —
# running switch-client from inside a popup gets undone when the popup closes.
# run-shell uses tmux's server env, so make sure Homebrew bins are on PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

self="${BASH_SOURCE[0]}"
cyan=$'\033[1;36m'; grn=$'\033[32m'; dim=$'\033[2m'; ylw=$'\033[33m'; rst=$'\033[0m'

# Robot suffix = running an AI coding agent. Loader = agent is busy right now.
robot=" ${ylw}🤖${rst}"
loader=" ${cyan}⟳${rst}"

# panes_busy <list-panes-args...> -> 0 if a pane shows an "in progress" marker.
# While working, Claude Code shows a live status line — an elapsed timer in
# parens and a token counter, e.g. "✶ Working… (1m 45s · ↓ 7.0k tokens)" — and
# Codex shows "Esc to interrupt". None of these appear when idle at the prompt.
busy_re='esc to interrupt|esc to cancel|tokens\)|\([0-9][0-9hms: ]*·'
panes_busy() {
  local id
  for id in $(tmux list-panes "$@" -F '#{pane_id}' 2>/dev/null); do
    tmux capture-pane -p -t "$id" 2>/dev/null | grep -qiE "$busy_re" && return 0
  done
  return 1
}

# One process snapshot, reused for all agent lookups (cheap, avoids per-pane ps).
ps_snap="$(ps -axo pid=,ppid=,comm= 2>/dev/null || true)"

# agent_name <pid>...  -> prints the agent name (claude|codex|pi) found in the
# process subtree of any pid, else prints nothing and returns 1.
# pane_current_command is unreliable (claude reports a version string, agents
# hide under make/zsh), so we walk the full process subtree instead.
agent_name() {
  [ -n "${1:-}" ] || return 1
  local m
  m="$(awk -v roots="$*" '
    BEGIN { n = split(roots, r, " "); for (i = 1; i <= n; i++) want[r[i]] = 1 }
    { pid[NR] = $1; ppid[NR] = $2; comm[NR] = $3 }
    END {
      do {                                   # mark all descendants of the roots
        changed = 0
        for (i = 1; i <= NR; i++)
          if (!want[pid[i]] && want[ppid[i]]) { want[pid[i]] = 1; changed = 1 }
      } while (changed)
      for (i = 1; i <= NR; i++) {
        c = comm[i]; sub(/.*\//, "", c)       # basename of the command
        if (want[pid[i]] && c ~ /^(claude|codex|pi)$/ && !seen[c]++)
          out = out (out ? " " : "") c         # distinct agents, in order found
      }
      if (out) print out
    }
  ' <<< "$ps_snap")"
  [ -n "$m" ] && printf '%s' "$m"
}

# Label subcommand (invoked from window-status-format via #()): print the agent
# name running under a pane, else the fallback command. Lets the status bar show
# "claude"/"codex" instead of the bogus pane_current_command (e.g. 2.1.158).
#   usage: tmux_window_manager.sh --label <pane_pid> <fallback_command>
if [ "${1:-}" = "--label" ]; then
  name="$(agent_name "${2:-}" 2>/dev/null || true)"
  printf '%s' "${name:-${3:-}}"
  exit 0
fi

# Preview subcommand (invoked by fzf): render EVERY pane of the target window,
# stacked and labeled — so split windows show all panes, not just the active one.
if [ "${1:-}" = "--preview" ]; then
  tgt="${2:-}"
  [ -n "$tgt" ] || exit 0
  first=1
  while IFS=$'\t' read -r pid pidx pcmd pw ph pa ppid; do
    [ "$first" = 1 ] || printf '\n'
    first=0
    mark=""; [ "$pa" = "1" ] && mark=" ${grn}●${rst}"
    pname="$(agent_name "$ppid" || true)"; pname="${pname:-$pcmd}"   # agent name over version
    printf '%s── pane %s%s  %s  [%sx%s] %s\n' "$dim" "$pidx" "$mark" "$pname" "$pw" "$ph" "$rst"
    # capture the pane, dropping trailing blank lines so panes stack compactly
    tmux capture-pane -ep -t "$pid" 2>/dev/null \
      | awk '{ b[NR]=$0 } /[^[:space:]]/ { last=NR } END { for (i=1;i<=last;i++) print b[i] }' \
      || true
  done < <(
    tmux list-panes -t "$tgt" \
      -F '#{pane_id}	#{pane_index}	#{pane_current_command}	#{pane_width}	#{pane_height}	#{pane_active}	#{pane_pid}' \
      2>/dev/null
  )
  exit 0
fi

# Client that invoked the keybinding (passed in), so we switch the right one.
client="${1:-}"

# Each emitted line is: <target>\t<display>
#   target  = "session:window_index" for windows, or "session" for header rows
#   display = colored, indented label shown by fzf (--with-nth=2)
# Header rows carry the session as target so searching/selecting a session name
# switches to that session's current window (window rows don't repeat the name).
build() {
  local prev="" sicon wicon agent label sname sagent
  while IFS=$'\t' read -r sess idx active name cmd; do
    if [ "$sess" != "$prev" ]; then
      # header shows the agent name(s) running anywhere in the session, a robot,
      # plus a loader if any of those agents is currently busy.
      sicon=""; sname=""
      sagent="$(agent_name $(tmux list-panes -s -t "$sess" -F '#{pane_pid}' 2>/dev/null) || true)"
      if [ -n "$sagent" ]; then
        sicon="$robot"
        panes_busy -s -t "$sess" && sicon="$sicon$loader"
        sname=" $dim$sagent$rst"
      fi
      printf '%s\t%s%s%s%s%s\n' "$sess" "$cyan" "$sess" "$rst" "$sname" "$sicon"  # session header
      prev="$sess"
    fi
    local dot="  "
    [ "$active" = "1" ] && dot="${grn}●${rst} "
    # When an agent is running, show its name instead of the (often bogus)
    # window name / pane_current_command (e.g. a version string like 2.1.158).
    wicon=""
    agent="$(agent_name $(tmux list-panes -t "$sess:$idx" -F '#{pane_pid}' 2>/dev/null) || true)"
    if [ -n "$agent" ]; then
      wicon="$robot"
      panes_busy -t "$sess:$idx" && wicon="$wicon$loader"
      label="$agent"
    else
      label="$name $dim($cmd)$rst"
    fi
    printf '%s:%s\t   %s%s%s:%s %s%s\n' \
      "$sess" "$idx" "$dot" "$dim" "$idx" "$rst" "$label" "$wicon"
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
      --preview="'$self' --preview {1}" \
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
