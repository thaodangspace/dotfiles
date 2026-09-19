#!/bin/bash
# One-time setup per machine: focus-space.sh falls back to these when the target
# space is empty. Safe to re-run. Equivalent to ticking "Switch to Desktop N" in
# System Settings → Keyboard → Keyboard Shortcuts → Mission Control.
# Enable Mission Control "Switch to Desktop N" = ctrl+N (symbolic hotkey ids 118..126)
# parameters = (ascii code, virtual keycode, modifier flags); 262144 = ctrl
set -e
keycodes=(18 19 20 21 23 22 26 28 25)
for n in 1 2 3 4 5 6 7 8 9; do
  id=$((117+n)); ascii=$((48+n)); kc=${keycodes[$((n-1))]}
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>$ascii</integer><integer>$kc</integer><integer>262144</integer></array></dict></dict>"
done
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys | python3 -c "
import sys,re;t=sys.stdin.read()
for k in range(118,127):
    m=re.search(r'\n\s*%d = \{(.*?)\n\s*\};'%k,t,re.S); print(k, ('enabled='+re.search(r'enabled = (\d)',m.group(1)).group(1)+' params='+re.search(r'parameters =\s*\(([^)]*)\)',m.group(1)).group(1).replace(chr(10),' ')) if m else 'absent')"
