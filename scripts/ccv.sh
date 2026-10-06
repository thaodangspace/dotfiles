#!/usr/bin/env bash
# ccv: start Claude Code with whichever account still has usage left.
#
# Usage: ccv [--status] [claude args...]
#   --status   print the usage table and exit, without starting claude
#
# Accounts are read from the cc_* aliases in ~/.zshrc (the CLAUDE_CONFIG_DIR each
# one sets), so add an account only there. Override with CCV_ACCOUNTS="dir1 dir2",
# names relative to $CCV_ROOT (default ~/CLAUDE_CONFIG_DIR).
#
# Usage comes from the OAuth usage endpoint behind Claude Code's /usage
# (undocumented, may change). The token is read from the macOS Keychain entry
# Claude Code writes for each config dir and is never printed. When an account
# can't be queried (no token, expired, API error), ccv falls back to scanning
# that account's recent transcripts for a "limit reached" message.

set -uo pipefail

CCV_ROOT="${CCV_ROOT:-$HOME/CLAUDE_CONFIG_DIR}"
CCV_THRESHOLD="${CCV_THRESHOLD:-99}" # % above which an account counts as exhausted
USAGE_URL="https://api.anthropic.com/api/oauth/usage"

status_only=0
if [ "${1:-}" = "--status" ]; then
  status_only=1
  shift
fi

command -v jq >/dev/null || { echo "ccv: jq is required" >&2; exit 1; }

# Claude Code stores credentials for a non-default CLAUDE_CONFIG_DIR under
# "Claude Code-credentials-<first 8 hex of sha256(config dir)>".
read_token() {
  local dir="$1" suffix creds
  suffix=$(printf '%s' "$dir" | shasum -a 256 | cut -c1-8)
  creds=$(security find-generic-password -a "$USER" -s "Claude Code-credentials-$suffix" -w 2>/dev/null) ||
    creds=$(cat "$dir/.credentials.json" 2>/dev/null) || return 1
  printf '%s' "$creds" | jq -er --argjson now "$(date +%s)000" '
    .claudeAiOauth | select(.expiresAt == null or .expiresAt > $now) | .accessToken'
}

# Fallback: did any transcript touched in the last 5h end up on a usage limit?
recently_limited() {
  local dir="$1"
  [ -d "$dir/projects" ] || return 1
  find "$dir/projects" -name '*.jsonl' -mmin -300 -print0 2>/dev/null |
    xargs -0 grep -l -i -m1 'limit reached' 2>/dev/null | grep -q .
}

# Writes one line to $out: "<score> <name> <detail>".
# score: max(5h, 7d) utilization; 101 = known to be limited; 500 = unknown.
probe() {
  local dir="$1" out="$2" name token json five seven
  name=$(basename "$dir")
  if token=$(read_token "$dir") &&
    json=$(curl -sf --max-time 8 "$USAGE_URL" \
      -H "Authorization: Bearer $token" \
      -H "anthropic-beta: oauth-2025-04-20") &&
    five=$(printf '%s' "$json" | jq -er '.five_hour.utilization // 0 | floor') &&
    seven=$(printf '%s' "$json" | jq -er '.seven_day.utilization // 0 | floor'); then
    local score=$((five > seven ? five : seven))
    echo "$score $name 5h=${five}% 7d=${seven}%" >"$out"
  elif recently_limited "$dir"; then
    echo "101 $name limit-reached (from transcripts)" >"$out"
  else
    echo "500 $name unknown (no usable token; start its cc_* alias once to refresh)" >"$out"
  fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

accounts="${CCV_ACCOUNTS:-$(sed -nE \
  's|^alias cc_[A-Za-z0-9_]+=.CLAUDE_CONFIG_DIR=\$HOME/CLAUDE_CONFIG_DIR/([^ ]+) claude.*|\1|p' \
  "$HOME/.zshrc")}"

for name in $accounts; do
  dir="$CCV_ROOT/$name"
  if [ -d "$dir" ]; then
    probe "$dir" "$tmp/$name" &
  else
    echo "999 $name not-logged-in (dir missing)" >"$tmp/$name"
  fi
done
wait

results=$(cat "$tmp"/* 2>/dev/null | sort -n)
[ -n "$results" ] || { echo "ccv: no accounts found in $CCV_ROOT" >&2; exit 1; }

if [ "$status_only" = 1 ]; then
  printf '%s\n' "$results" | cut -d' ' -f2- | column -t
  exit 0
fi

# Best known account under the threshold, else the first unknown one.
pick=$(printf '%s\n' "$results" | awk -v t="$CCV_THRESHOLD" '$1 < t {print $2; exit}')
[ -n "$pick" ] || pick=$(printf '%s\n' "$results" | awk '$1 == 500 {print $2; exit}')

if [ -z "$pick" ]; then
  echo "ccv: every account is at or above ${CCV_THRESHOLD}%:" >&2
  printf '%s\n' "$results" | cut -d' ' -f2- | column -t >&2
  exit 1
fi

echo "ccv: using $(printf '%s\n' "$results" | awk -v p="$pick" '$2 == p {$1=""; print substr($0, 2)}')" >&2
rm -rf "$tmp" # exec skips the EXIT trap
CLAUDE_CONFIG_DIR="$CCV_ROOT/$pick" exec claude "$@"
