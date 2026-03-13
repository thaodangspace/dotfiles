#!/bin/sh

CCS="$HOME/code/claude-code-switcher/ccs"
STATE_FILE="/tmp/claude_code_cycle.state"

CYCLE_ORDER="glm local qwen personal vsee"
PROVIDERS="glm local"
ACCOUNTS="personal vsee"

cycle() {
  if [ -f "$STATE_FILE" ]; then
    index=$(cat "$STATE_FILE")
  else
    index=-1
  fi

  index=$((index + 1))

  count=0
  for _ in $CYCLE_ORDER; do
    count=$((count + 1))
  done

  if [ $index -ge $count ]; then
    index=0
  fi

  i=0
  for option in $CYCLE_ORDER; do
    if [ $i -eq $index ]; then
      next="$option"
      break
    fi
    i=$((i + 1))
  done

  echo "$index" >"$STATE_FILE"

  if echo "$ACCOUNTS" | grep -qw "$next"; then
    "$CCS" account "$next" 2>&1
  else
    "$CCS" "$next" 2>&1
  fi
}

if [ "$1" = "click" ]; then
  cycle
fi

CCS_OUTPUT=$("$CCS" current 2>&1)

sketchybar --set "$NAME" label="$CCS_OUTPUT"
