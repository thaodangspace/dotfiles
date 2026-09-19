# yabai

Deployed with `stow -t ~/.config/yabai yabai`. Hotkeys live in `../skhd/skhdrc`.

| file | purpose |
| --- | --- |
| `yabairc` | settings, per-app rules, scripting-addition load, signals |
| `focus-space.sh` | `alt-N`: `space --focus` via the SA, verified; falls back to focusing a window on the space, then to the native ctrl-N shortcut |
| `route.sh` | `window_created` signal: windows of apps with no per-app rule go to space 7 (`UNROUTED_SPACE` in `yabairc`) and focus follows; reads the rules back from `yabai -m rule --list`, so the app list lives only in `yabairc` |
| `update-sudoers.sh` | re-pin the passwordless `sudo yabai --load-sa` rule to the current binary hash and load the SA |
| `enable-desktop-hotkeys.sh` | one-time: enable Mission Control "Switch to Desktop N" (ctrl-N) used as the last fallback |

## Scripting addition (SA) — state of this machine (2026-09-19)

SIP is partially disabled so the SA can be injected into the Dock. This is what
gives instant, animation-free space switching and lets `space --focus` reach
empty spaces. Done once, in Recovery (hold power → Options → Utilities → Terminal):

```sh
csrutil enable --without fs --without debug --without nvram
# reboot, then in a normal terminal (Apple Silicon only):
sudo nvram boot-args=-arm64e_preview_abi
# reboot again. Verify:
csrutil status          # "unknown (Custom Configuration)", fs/debug/nvram disabled
sysctl kern.bootargs    # -arm64e_preview_abi
```

`yabairc` runs `sudo yabai --load-sa` at start and on `dock_did_restart`.
That works without a password because `/private/etc/sudoers.d/yabai` allows
exactly `<sha256 of the yabai binary> /opt/homebrew/bin/yabai --load-sa`.

### macOS 27 and the fork build

yabai 7.1.25 (latest brew release, 2026-05) only knows macOS ≤ 26: on 27 the SA
payload's `verify_os_version()` fails, `--load-sa` still returns 0, and every
space operation is a silent no-op. Tracking issues: asmvik/yabai#2800, #2802,
#2822. Until an official release ships, the Cellar binary is a build of
[ImTheSquid/yabai](https://github.com/ImTheSquid/yabai) (commit `3b463fc`,
"macOS 27 offsets"; diff vs upstream is only SA offsets/patterns + `26 || 27`
version aliasing). Backup of the brew binary:
`/opt/homebrew/Cellar/yabai/7.1.25/bin/yabai.brew-original`.

Rebuild from the fork:

```sh
git clone --depth 1 https://github.com/ImTheSquid/yabai.git && cd yabai
make install                       # -> bin/yabai (needs Xcode CLT)
codesign -fs - bin/yabai           # ad-hoc, same as the brew formula
install -m 555 bin/yabai /opt/homebrew/Cellar/yabai/7.1.25/bin/yabai
```

`cp -p` into the Cellar fails with "Permission denied" because of the
`com.apple.provenance` xattr — use `install` or plain `cp`.

### Whenever the yabai binary changes (`brew upgrade yabai`, fork rebuild)

Two things are bound to the binary and break silently:

1. **sudoers hash** → run `~/.config/yabai/update-sudoers.sh` in a real terminal
   (asks for the password; `!`-prefixed commands in Claude Code have no TTY).
2. **Accessibility** → the TCC entry is bound to the ad-hoc cdhash. Toggling it
   off/on is *not* enough and `tccutil reset Accessibility com.asmvik.yabai`
   fails (bare binary, no bundle). In System Settings → Privacy & Security →
   Accessibility: remove `yabai` with `−`, re-add
   `/opt/homebrew/Cellar/yabai/7.1.25/bin/yabai` with `+` (or drag it from
   `open -R <path>`), enable it. Symptom when skipped: yabai exits with
   `could not access accessibility features! abort..` and launchd does not retry.
3. `yabai --restart-service`.

If the new binary's SA does not support the running macOS, nothing breaks:
`focus-space.sh` verifies the switch and falls back to the animated paths.
Signing with a fixed self-signed certificate instead of ad-hoc would make step 2
unnecessary (see the yabai wiki) — not done yet.

### Checks

```sh
yabai -m space --focus 3 && yabai -m query --spaces --space | jq .index   # instant, works on empty spaces
tail /tmp/yabai_$USER.err.log                                             # "load-sa failed" → sudoers hash stale
yabai -m signal --list | jq -r '.[].label'                                # route-unconfigured, reload-sa
```

## Spaces

Display 1: spaces 1–5, display 2: 6–7. Spaces are plain Mission Control spaces
and must exist; `rule()` in `yabairc` logs and drops `space=` when one is
missing, `route.sh` leaves the window alone. App → space: 1 terminals/editors,
2 browsers, 3 writing/Xcode, 4 chat, 5 misc, 7 everything without a rule.
