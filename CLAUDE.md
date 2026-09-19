# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository for macOS containing configuration files for various development tools and applications. The repository uses GNU Stow for symlink management to deploy configurations to their proper locations.

## Setup Commands

### Initial Setup
```bash
# Install dependencies via Homebrew
brew bundle install

# Deploy all configurations using stow
stow -t ~/.config/nvim nvim
stow -t ~/.config/ghostty ghostty
stow -t ~/.config/scripts scripts
stow -t ~/.qutebrowser qutebrowser
mkdir -p ~/.config/yabai ~/.config/skhd
stow -t ~/.config/yabai yabai
stow -t ~/.config/skhd skhd
stow -t ~ aerospace   # legacy fallback, do not run alongside yabai
stow -t ~ zsh
stow -t ~ wezterm
stow -t ~ tmux

# Fish: pre-create real dirs so stow links files, not whole directories
mkdir -p ~/.config/fish/{conf.d,functions,completions}
stow -t ~/.config/fish fish
```

### Individual Configuration Deployment
Use `stow -t <target> <package>` to deploy specific configurations:
- `stow -t ~/.config/nvim nvim` - Deploy Neovim configuration
- `stow -t ~/.config/yabai yabai` / `stow -t ~/.config/skhd skhd` - Deploy yabai + skhd (see Window Manager below)
- `stow -t ~ aerospace` - Deploy the legacy AeroSpace config (fallback only)
- `stow -t ~/.config/fish fish` - Deploy Fish shell config (see Fish Shell below)

## Architecture

### Core Components

**Window Management & UI**
- `yabai/` - yabai tiling window manager config (`yabairc`: settings, app rules, SA load) plus `focus-space.sh`, `route.sh`, `update-sudoers.sh`; `yabai/README.md` documents the SIP/scripting-addition setup
- `skhd/` - skhd hotkeys for yabai (`skhdrc`), same alt-based bindings the AeroSpace config had
- `aerospace/` - Previous AeroSpace config, kept as a fallback (not active)
- `tmux/` - Terminal multiplexer configuration
- `yazi/` - File manager configuration

**Shell**
- `fish/` - Fish shell (login shell), Fisher plugin manager, Tide prompt
- `zsh/` - Previous zsh + oh-my-zsh + starship config, kept for fallback

**Development Environment** 
- `nvim/` - Neovim configuration using LazyVim distribution (has its own CLAUDE.md)
- `zed/` - Zed editor configuration with vim mode enabled
- `ghostty/` - Terminal emulator configuration
- `wezterm/` - Alternative terminal emulator configuration

**Browser & Scripts**
- `qutebrowser/` - Vim-like browser configuration
- `scripts/` - Utility scripts for floating windows (Ghostty, Qutebrowser)

### Configuration Management

The repository follows a modular approach where each application has its own directory containing all necessary configuration files. GNU Stow creates symlinks from these directories to the appropriate system locations.

### Window Manager (yabai + skhd)

yabai (from the `asmvik/formulae` tap, the new home of koekeishiya/yabai) replaced
AeroSpace. skhd provides the hotkeys. Both run as launchd services:

- `yabai --start-service` / `yabai --restart-service` — yabai reads `~/.config/yabai/yabairc`
- `skhd --start-service` / `skhd --reload` — skhd reads `~/.config/skhd/skhdrc`
- Logs: `/tmp/yabai_$USER.err.log`, `/tmp/skhd_$USER.err.log`
- Both need Accessibility permission (System Settings → Privacy & Security → Accessibility).

SIP is partially disabled (`--without fs --without debug --without nvram`,
`boot-args=-arm64e_preview_abi`) and `yabairc` loads the scripting addition
(SA) via a passwordless `sudo yabai --load-sa` pinned to the binary's sha256 in
`/private/etc/sudoers.d/yabai`. yabai 7.1.25's SA does not support macOS 27, so
the Cellar binary is a build of the ImTheSquid/yabai fork (macOS 27 offsets);
the brew original is kept next to it as `yabai.brew-original`. **After any
change of the yabai binary** (brew upgrade, rebuild) run
`yabai/update-sudoers.sh` and remove/re-add yabai in Accessibility — otherwise
yabai aborts with "could not access accessibility features" or the SA silently
does nothing. Full procedure in `yabai/README.md`.

`alt-N` runs `yabai/focus-space.sh`: `yabai -m space --focus N` (instant with
the SA), verified, else focus a window on the target space, else the native
ctrl-N Mission Control shortcut (enabled via `com.apple.symbolichotkeys`, ids
118–126). Workspaces are plain Mission Control spaces and must exist (display 1:
1–5, display 2: 6–7). `yabai/route.sh` (signal `window_created`) moves windows
of apps without a per-app rule to space 7 and follows them; it reads the rules
back from `yabai -m rule --list`, so add apps only in `yabairc`.

Mapping from the old AeroSpace config: `[[on-window-detected]]` → `yabai -m rule`
(matched on app *name*, not bundle id; everything floats by default and the
per-app rules re-enable tiling), `[mode.main.binding]` → `skhdrc`,
`[mode.service.binding]` → the skhd `service` mode (`alt-shift-;`), gaps →
`window_gap` / `*_padding` / `external_bar`.

### Key Dependencies

From Brewfile, important tools include:
- `stow` - Configuration deployment
- `fish` - Login shell (Fisher for plugins, Tide for the prompt)
- `neovim` - Primary editor
- `tmux` - Terminal multiplexer  
- `asmvik/formulae/yabai` + `asmvik/formulae/skhd` - Window manager and hotkeys
- `jq` - used by `yabai/focus-space.sh`, `yabai/route.sh` and skhd bindings
- Development tools: `go`, `node`, `python@3.13`, `uv`

## Development Commands

### Neovim Configuration
See `nvim/CLAUDE.md` for detailed Neovim-specific guidance including:
- `stylua .` - Format Lua code
- `:Lazy` commands for plugin management

### Configuration Testing
- Restart applications after making changes to test configurations
- For yabai: `yabai --restart-service`; for skhd: `skhd --reload`

### Fish Shell

Fish is the login shell (`/opt/homebrew/bin/fish`); `zsh/` is kept as a fallback.

- Plugins are managed by **Fisher**, declared in `fish/fish_plugins`. Add one with
  `fisher install <owner>/<repo>` and commit the updated `fish_plugins`; `fisher update`
  installs everything in the manifest.
- The prompt is **Tide** (Lean, two-line). Tide's settings live in fish *universal*
  variables (`~/.config/fish/fish_variables`), which is untracked machine state — change
  the prompt with `tide configure`, and mirror any change you want to keep into
  `fish/tide-setup.fish` so other machines reproduce it.
- Only `config.fish`, `conf.d/`, `functions/fish_title.fish`, `fish_plugins` and
  `tide-setup.fish` are tracked. Everything else fisher writes into `~/.config/fish`
  (tide's ~60 `_tide_*` functions, `completions/`, `conf.d/_tide_init.fish`) is
  generated and must stay out of the repo.
- New PATH entries go in `fish/conf.d/00-path.fish` via `fish_add_path -gP`, which
  silently skips directories that don't exist. Use `-g` (global), never `-U`
  (universal), so PATH is re-derived cleanly each session.
- Changes to `conf.d/` take effect in new shells; `exec fish` reloads the current one.

### Script Management
Utility scripts in `scripts/` directory:
- `float_ghostty.sh` - Create floating Ghostty terminal windows
- `float_qutebrowser.sh` - Create floating Qutebrowser windows

## Configuration Notes

- Zed editor is configured with vim mode enabled and system theme switching
- Terminal configurations prioritize Nerd Font support (BlexMono, Hack Nerd Font)
- All configurations assume macOS environment with Homebrew package management
- Window management relies on yabai + skhd; workspaces are plain Mission Control spaces