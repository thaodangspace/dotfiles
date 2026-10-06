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
mkdir -p ~/.config/herdr
stow -t ~/.config/herdr herdr   # keybindings ported from tmux/.tmux.conf
```

### Individual Configuration Deployment
Use `stow -t <target> <package>` to deploy specific configurations:
- `stow -t ~/.config/nvim nvim` - Deploy Neovim configuration
- `stow -t ~/.config/yabai yabai` / `stow -t ~/.config/skhd skhd` - Deploy yabai + skhd (see Window Manager below)
- `stow -t ~ aerospace` - Deploy the legacy AeroSpace config (fallback only)
- `stow -t ~ zsh` - Deploy the zsh config (see Zsh Shell below)

## Architecture

### Core Components

**Window Management & UI**
- `yabai/` - yabai tiling window manager config (`yabairc`: settings, app rules, SA load) plus `focus-space.sh`, `route.sh`, `update-sudoers.sh`; `yabai/README.md` documents the SIP/scripting-addition setup
- `skhd/` - skhd hotkeys for yabai (`skhdrc`), same alt-based bindings the AeroSpace config had
- `aerospace/` - Previous AeroSpace config, kept as a fallback (not active)
- `tmux/` - Terminal multiplexer configuration
- `yazi/` - File manager configuration

**Shell**
- `zsh/` - zsh (login shell): oh-my-zsh + starship, `.zshrc` stowed to `~`
- `fish/` - Previous Fish + Fisher + Tide config, kept as a fallback (not active)

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
- `starship` - zsh prompt (oh-my-zsh itself is installed outside Homebrew)
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

### Zsh Shell

zsh is the login shell (`/bin/zsh`); `fish/` is kept as a fallback and is not
deployed (to restore it see git history of this file).

- `zsh/.zshrc` is stowed to `~/.zshrc` and loads oh-my-zsh (`plugins=(git
  zsh-autosuggestions)`), then the starship prompt.
- PATH entries and aliases go directly in `zsh/.zshrc`.
- Claude Code accounts are `cc_*` aliases there, one `CLAUDE_CONFIG_DIR` under
  `~/CLAUDE_CONFIG_DIR/` each; `ccv` (see Script Management) reads that alias
  list, so add accounts only as aliases.
- Changes take effect in new shells; `exec zsh` reloads the current one.

### Script Management
Utility scripts in `scripts/` directory:
- `float_ghostty.sh` - Create floating Ghostty terminal windows
- `float_qutebrowser.sh` - Create floating Qutebrowser windows
- `ccv.sh` - `ccv` alias: start Claude Code with the `cc_*` account (from `zsh/.zshrc`) that has the most usage left; `ccv --status` prints the table

## Configuration Notes

- Zed editor is configured with vim mode enabled and system theme switching
- Terminal configurations prioritize Nerd Font support (BlexMono, Hack Nerd Font)
- All configurations assume macOS environment with Homebrew package management
- Window management relies on yabai + skhd; workspaces are plain Mission Control spaces