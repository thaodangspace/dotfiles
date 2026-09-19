#!/usr/bin/env bash
# Re-pin the sudoers rule that lets `sudo yabai --load-sa` run without a
# password. The rule is bound to the sha256 of the yabai binary, so run this
# after every `brew upgrade yabai` or manual swap of the binary, then
# `yabai --restart-service`. Asks for your password (sudo tee).
set -eu
bin=$(which yabai)
hash=$(shasum -a 256 "$bin" | cut -d ' ' -f 1)
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$hash $bin --load-sa" | sudo tee /private/etc/sudoers.d/yabai
sudo yabai --load-sa && echo "scripting addition loaded" || echo "load-sa failed, check /tmp/yabai_$USER.err.log" >&2
