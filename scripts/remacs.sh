#!/usr/bin/env bash

set -euo pipefail

# Usage: remacs.sh user@host [emacsclient args]
# Forwards the remote emacs server socket and launches a local emacsclient

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 user@host [-- emacsclient args]" >&2
  exit 1
fi

TARGET="$1"; shift || true

LOCAL_UID="$(id -u)"
LOCAL_DIR="/tmp/emacs-${LOCAL_UID}"
REMOTE_UID="$(ssh -o ControlMaster=auto -o ControlPersist=60 -o ControlPath=~/.ssh/controlmasters/%r@%h:%p -q "$TARGET" id -u)"
SOCKET_NAME="server-$(ssh -q "$TARGET" hostname)"
LOCAL_SOCKET="${LOCAL_DIR}/${SOCKET_NAME}"

mkdir -p "$LOCAL_DIR" ~/.ssh/controlmasters

# Ensure remote server is running
ssh -o ControlMaster=auto -o ControlPersist=60 -o ControlPath=~/.ssh/controlmasters/%r@%h:%p "$TARGET" \
  "emacsclient -s '${SOCKET_NAME}' -e t >/dev/null 2>&1 || nohup emacs --daemon='${SOCKET_NAME}' >/dev/null 2>&1 & disown"

# Detect remote server socket directory via emacsclient
REMOTE_DIR_RAW="$(ssh -o ControlMaster=auto -o ControlPersist=60 -o ControlPath=~/.ssh/controlmasters/%r@%h:%p -q "$TARGET" \
  emacsclient -s "${SOCKET_NAME}" -e '(expand-file-name server-socket-dir)')"
# emacsclient prints a Lisp string like "\"/path\""; strip quotes
REMOTE_DIR="${REMOTE_DIR_RAW%\"}"; REMOTE_DIR="${REMOTE_DIR#\"}"
REMOTE_SOCKET="${REMOTE_DIR}/${SOCKET_NAME}"

# Create local SSH port forward for the UNIX socket using socat as a bridge if needed
# We emulate a socket forward via ssh + socat over stdio

if command -v socat >/dev/null 2>&1; then
  # Kill any existing socat for this socket
  pkill -f "socat UNIX-LISTEN:${LOCAL_SOCKET}" >/dev/null 2>&1 || true
  # Start a background bridge: local UNIX socket <-> ssh remote UNIX socket
  nohup sh -c "socat UNIX-LISTEN:${LOCAL_SOCKET},fork EXEC:'ssh -T ${TARGET} socat - UNIX-CLIENT:\\'${REMOTE_SOCKET}\\''" >/dev/null 2>&1 &
  # Wait briefly for socket to appear
  for i in {1..20}; do
    [[ -S \"${LOCAL_SOCKET}\" ]] && break
    sleep 0.1
  done
fi

# Launch emacsclient locally targeting the forwarded socket
exec emacsclient -s "${SOCKET_NAME}" -c "$@"


