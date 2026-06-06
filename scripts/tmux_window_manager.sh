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

# Global associative arrays to cache t2 agents data and pane paths
declare -A agent_names
declare -A agent_ages
declare -A agent_models
declare -A agent_prompts
declare -A agent_messages
declare -A pane_pid_paths
declare -A pane_id_paths

cache_file="/tmp/t2_agents_cache_${USER:-shared}.json"

populate_mappings_cache_only() {
  # 1. Populate agent info from cached file if exists
  if [ -f "$cache_file" ]; then
    while IFS="|" read -r cwd agent age model prompt message; do
      [ -n "$cwd" ] || continue
      agent_names["$cwd"]="$agent"
      agent_ages["$cwd"]="$age"
      agent_models["$cwd"]="$model"
      agent_prompts["$cwd"]="$prompt"
      agent_messages["$cwd"]="$message"
    done < <(jq -r '.sessions[] | "\(.cwd)|\(.agent)|\(.ageSeconds)|\(.model // "")|\(.prompt // "" | gsub("\n"; " ") | gsub("\\|"; " "))|\(.latestMessage // "" | gsub("\n"; " ") | gsub("\\|"; " "))"' "$cache_file" 2>/dev/null)
  fi

  # 2. Populate pane paths mapping from tmux
  while read -r id pid path; do
    [ -n "$id" ] || continue
    pane_id_paths["$id"]="$path"
    pane_pid_paths["$pid"]="$path"
  done < <(tmux list-panes -a -F '#{pane_id} #{pane_pid} #{pane_current_path}' 2>/dev/null)
}

populate_mappings() {
  # 1. Populate agent info from t2 agents --format json
  local json
  json="$(t2 agents --format json 2>/dev/null || echo '{"sessions":[]}')"
  while IFS="|" read -r cwd agent age model prompt message; do
    [ -n "$cwd" ] || continue
    agent_names["$cwd"]="$agent"
    agent_ages["$cwd"]="$age"
    agent_models["$cwd"]="$model"
    agent_prompts["$cwd"]="$prompt"
    agent_messages["$cwd"]="$message"
  done < <(echo "$json" | jq -r '.sessions[] | "\(.cwd)|\(.agent)|\(.ageSeconds)|\(.model // "")|\(.prompt // "" | gsub("\n"; " ") | gsub("\\|"; " "))|\(.latestMessage // "" | gsub("\n"; " ") | gsub("\\|"; " "))"' 2>/dev/null)

  # 2. Populate pane paths mapping from tmux
  while read -r id pid path; do
    [ -n "$id" ] || continue
    pane_id_paths["$id"]="$path"
    pane_pid_paths["$pid"]="$path"
  done < <(tmux list-panes -a -F '#{pane_id} #{pane_pid} #{pane_current_path}' 2>/dev/null)
}

# panes_busy <list-panes-args...> -> 0 if a pane shows an "in progress" marker.
# While working, Claude Code shows a live status line — an elapsed timer in
# parens and a token counter, e.g. "✶ Working… (1m 45s · ↓ 7.0k tokens)" — and
# Codex shows "Esc to interrupt". None of these appear when idle at the prompt.
busy_re='esc to interrupt|esc to cancel|tokens\)|\([0-9][0-9hms: ]*·'
panes_busy() {
  local id path age
  # Try checking via t2 agents age first
  for id in $(tmux list-panes "$@" -F '#{pane_id}' 2>/dev/null); do
    path="${pane_id_paths["$id"]:-}"
    if [ -n "$path" ]; then
      age="${agent_ages["$path"]:-}"
      if [ -n "$age" ] && [ "$age" -lt 30 ]; then
        return 0
      fi
    fi
  done

  # Fallback to capturing the pane content
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
  local pid path name seen="" out=""

  # Try mapping using t2 agents paths first
  for pid in "$@"; do
    path="${pane_pid_paths["$pid"]:-}"
    if [ -n "$path" ]; then
      name="${agent_names["$path"]:-}"
      if [ -n "$name" ] && [[ ! " $seen " == *" $name "* ]]; then
        out="${out}${out:+ }$name"
        seen="${seen}${seen:+ }$name"
      fi
    fi
  done

  if [ -n "$out" ]; then
    printf '%s' "$out"
    return 0
  fi

  # Fallback to the original process tree detection
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

# agent_model_suffix <pid>... -> prints (model) if the pid maps to a t2 agent path with a model, else nothing.
agent_model_suffix() {
  [ -n "${1:-}" ] || return 0
  local pid path model seen="" out=""
  for pid in "$@"; do
    path="${pane_pid_paths["$pid"]:-}"
    if [ -n "$path" ]; then
      model="${agent_models["$path"]:-}"
      if [ -n "$model" ] && [[ ! " $seen " == *" $model "* ]]; then
        out="${out}${out:+/}$model"
        seen="${seen}${seen:+ }$model"
      fi
    fi
  done
  if [ -n "$out" ]; then
    printf '(%s)' "$out"
  fi
}

# Each emitted line is: <target>\t<display>
#   target  = "session:window_index" for windows, or "session" for header rows
#   display = colored, indented label shown by fzf (--with-nth=2)
# Header rows carry the session as target so searching/selecting a session name
# switches to that session's current window (window rows don't repeat the name).
build() {
  local prev="" sicon wicon agent label sname sagent smodel model
  while IFS=$'\t' read -r sess idx active name cmd; do
    if [ "$sess" != "$prev" ]; then
      # header shows the agent name(s) running anywhere in the session, a robot,
      # plus a loader if any of those agents is currently busy.
      sicon=""; sname=""
      sagent="$(agent_name $(tmux list-panes -s -t "$sess" -F '#{pane_pid}' 2>/dev/null) || true)"
      if [ -n "$sagent" ]; then
        sicon="$robot"
        panes_busy -s -t "$sess" && sicon="$sicon$loader"
        smodel="$(agent_model_suffix $(tmux list-panes -s -t "$sess" -F '#{pane_pid}' 2>/dev/null) || true)"
        sname=" $dim$sagent$smodel$rst"
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
      model="$(agent_model_suffix $(tmux list-panes -t "$sess:$idx" -F '#{pane_pid}' 2>/dev/null) || true)"
      label="$agent$model"
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

# Build from cache subcommand (invoked by fzf reload)
if [ "${1:-}" = "--build-from-cache" ]; then
  populate_mappings_cache_only
  build
  exit 0
fi

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
  populate_mappings_cache_only

  # Print agent info at the top of the preview if mapped to a t2 agent
  seen_paths=""
  pids="$(tmux list-panes -t "$tgt" -F '#{pane_pid}' 2>/dev/null || true)"
  for pid in $pids; do
    path="${pane_pid_paths["$pid"]:-}"
    if [ -n "$path" ] && [ -n "${agent_names["$path"]:-}" ]; then
      if [[ ! " $seen_paths " == *" $path "* ]]; then
        seen_paths="${seen_paths}${seen_paths:+ }$path"
        name="${agent_names["$path"]}"
        age="${agent_ages["$path"]:-}"
        model="${agent_models["$path"]:-}"
        prompt="${agent_prompts["$path"]:-}"
        msg="${agent_messages["$path"]:-}"
        
        age_str=""
        if [ -n "$age" ]; then
          if [ "$age" -lt 60 ]; then
            age_str="${age}s ago"
          else
            age_str="$((age / 60))m $((age % 60))s ago"
          fi
        fi
        
        # Truncate prompt and message to reasonable lengths for preview
        if [ ${#prompt} -gt 300 ]; then
          prompt="${prompt:0:297}..."
        fi
        if [ ${#msg} -gt 500 ]; then
          msg="${msg:0:497}..."
        fi
        
        printf "%s🤖 %s%s" "${ylw}" "${name}" "${rst}"
        if [ -n "$model" ]; then
          printf " (%s%s%s)" "${cyan}" "${model}" "${rst}"
        fi
        if [ -n "$age_str" ]; then
          printf " — %s%s%s" "${dim}" "${age_str}" "${rst}"
        fi
        printf "\n"
        
        if [ -n "$prompt" ]; then
          printf "  %sPrompt:%s  %s%s%s\n" "${dim}" "${rst}" "${dim}" "${prompt}" "${rst}"
        fi
        if [ -n "$msg" ]; then
          printf "  %sLatest:%s  %s\n" "${dim}" "${rst}" "${msg}"
        fi
        printf "%s────────────────────────────────────────────────────────────────%s\n" "${dim}" "${rst}"
      fi
    fi
  done

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

# Open editor subcommand (invoked by fzf): open specified editor on the active pane's current directory
if [ "${1:-}" = "--open-editor" ]; then
  editor="${2:-}"
  tgt="${3:-}"
  [ -n "$tgt" ] || exit 0
  dir="$(tmux display-message -p -t "$tgt" '#{pane_current_path}' 2>/dev/null || true)"
  if [ -d "$dir" ]; then
    if [ "$editor" = "zed" ]; then
      if command -v zed >/dev/null 2>&1; then
        zed "$dir"
      else
        open -a Zed "$dir"
      fi
    elif [ "$editor" = "typora" ]; then
      if command -v typora >/dev/null 2>&1; then
        typora "$dir"
      else
        open -a Typora "$dir"
      fi
    fi
  fi
  exit 0
fi

# Popup inner subcommand (invoked by tmux display-popup)
if [ "${1:-}" = "--popup-inner" ]; then
  client="${2:-}"

  # Refresh agent data in the background; fzf starts from the current cache and
  # Ctrl-R can reload the cache after the refresh completes.
  (
    t2 agents --format json > "$cache_file" 2>/dev/null || true
  ) &

  # Load cached mappings immediately so fzf displays the window list instantly
  populate_mappings_cache_only

  err=0
  sel="$(
    build | fzf \
        --ansi --reverse --no-sort --prompt='window > ' \
        --delimiter=$'\t' --with-nth=2 \
        --preview="'$self' --preview {1}" \
        --preview-window='right,60%,wrap' \
        --bind "ctrl-z:execute-silent('$self' --open-editor zed {1})+abort,ctrl-t:execute-silent('$self' --open-editor typora {1})+abort" \
        --bind "ctrl-r:reload('$self' --build-from-cache)" \
        --border --header='Enter: switch | Ctrl-N: New | Ctrl-Z: Zed | Ctrl-T: Typora' \
        --print-query --expect=ctrl-n
  )" || err=$?

  client_safe="${client//\//_}"
  temp_sel_file="/tmp/tmux_wm_sel_${client_safe}.txt"
  temp_err_file="/tmp/tmux_wm_err_${client_safe}.txt"
  echo "$err" > "$temp_err_file"
  printf '%s\n' "$sel" > "$temp_sel_file"
  exit 0
fi

# Client that invoked the keybinding (passed in), so we switch the right one.
client="${1:-}"

client_safe="${client//\//_}"
temp_sel_file="/tmp/tmux_wm_sel_${client_safe}.txt"
temp_err_file="/tmp/tmux_wm_err_${client_safe}.txt"
rm -f "$temp_sel_file" "$temp_err_file"

# Open the popup running ourselves
printf -v popup_cmd '%q ' "$self" --popup-inner "$client"
tmux display-popup -E -w 85% -h 75% "$popup_cmd" || true

if [ ! -f "$temp_sel_file" ] || [ ! -f "$temp_err_file" ]; then
  exit 0
fi

err="$(cat "$temp_err_file")"
sel="$(cat "$temp_sel_file")"
rm -f "$temp_sel_file" "$temp_err_file"

if [ "$err" -eq 130 ]; then
  exit 0
fi

list_directories() {
  local current_dir="${1:-}"
  if [ -n "$current_dir" ]; then
    echo "$current_dir"
  fi
  echo "$HOME"
  if [ -d "$HOME/code" ]; then
    fd --type d --max-depth 3 --hidden --exclude .git --exclude node_modules --exclude Library --exclude .Trash . "$HOME/code" 2>/dev/null || true
  fi
  if [ -d "$HOME/go" ]; then
    fd --type d --max-depth 3 --hidden --exclude .git --exclude node_modules --exclude Library --exclude .Trash . "$HOME/go" 2>/dev/null || true
  fi
  fd --type d --max-depth 1 --exclude .git --exclude Library --exclude .Trash --exclude Applications --exclude Public --exclude OrbStack --exclude Movies --exclude Music --exclude Pictures --exclude code --exclude go . "$HOME" 2>/dev/null || true
}

resolve_path() {
  local input="$1"
  local base_dir="${2:-$HOME}"
  input="${input/#\~/$HOME}"
  if [[ "$input" == /* ]]; then
    echo "$input"
  else
    echo "$base_dir/$input"
  fi
}

mapfile -t lines <<< "$sel"
query="${lines[0]:-}"
key="${lines[1]:-}"
selection="${lines[2]:-}"

if [ "$key" = "ctrl-n" ]; then
  current_dir="$(tmux display-message -p -t "$client" -F '#{pane_current_path}' 2>/dev/null || echo "$HOME")"
  prompt_name="${query:-new session}"

  dir_err=0
  dir_sel="$(
    list_directories "$current_dir" | awk '!seen[$0]++' | fzf --tmux center,85%,75% \
        --ansi --reverse --no-sort --prompt="dir for '$prompt_name' > " \
        --print-query
  )" || dir_err=$?

  if [ "$dir_err" -eq 130 ] || [ -z "$dir_sel" ]; then
    exit 0
  fi

  mapfile -t dir_lines <<< "$dir_sel"
  dir_query="${dir_lines[0]:-}"
  dir_selection="${dir_lines[1]:-}"

  target_dir=""
  if [ -n "$dir_selection" ]; then
    target_dir="$dir_selection"
  elif [ -n "$dir_query" ]; then
    target_dir="$dir_query"
  fi

  [ -n "$target_dir" ] || exit 0

  target_dir="$(resolve_path "$target_dir" "$current_dir")"
  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
  fi

  session_name="$query"
  if [ -z "$session_name" ]; then
    session_name="$(basename "$target_dir")"
  fi
  session_name="${session_name//:/-}"

  # Build the switch-client args, targeting the launching client when known.
  set --
  [ -n "$client" ] && set -- -c "$client"

  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux new-window -t "$session_name" -c "$target_dir"
    tmux switch-client "$@" -t "$session_name"
  else
    tmux new-session -d -s "$session_name" -c "$target_dir"
    tmux switch-client "$@" -t "$session_name"
  fi
  exit 0
fi

target="${selection%%$'\t'*}"
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
