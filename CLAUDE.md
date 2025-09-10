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
stow -t ~/.config/sketchybar sketchybar
stow -t ~/.config/ghostty ghostty
stow -t ~/.config/scripts scripts
stow -t ~/.qutebrowser qutebrowser
stow -t ~ aerospace
stow -t ~ zsh
stow -t ~ wezterm
stow -t ~ tmux
```

### Individual Configuration Deployment
Use `stow -t <target> <package>` to deploy specific configurations:
- `stow -t ~/.config/nvim nvim` - Deploy Neovim configuration
- `stow -t ~/.config/sketchybar sketchybar` - Deploy SketchyBar status bar
- `stow -t ~ aerospace` - Deploy AeroSpace window manager config

## Architecture

### Core Components

**Window Management & UI**
- `aerospace/` - AeroSpace tiling window manager configuration
- `sketchybar/` - macOS status bar with custom plugins and Aerospace integration
- `tmux/` - Terminal multiplexer configuration
- `yazi/` - File manager configuration

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

### SketchyBar Integration

SketchyBar is configured to integrate with AeroSpace window manager:
- Workspace switching notifications via `exec-on-workspace-change`
- Custom plugins in `sketchybar/plugins/` for system information (battery, memory, clock, etc.)
- Aerospace-specific plugins for workspace and window management

### Key Dependencies

From Brewfile, important tools include:
- `stow` - Configuration deployment
- `neovim` - Primary editor
- `tmux` - Terminal multiplexer  
- `sketchybar` - Status bar
- `aerospace` - Window manager
- Development tools: `go`, `node`, `python@3.13`, `uv`

## Development Commands

### Neovim Configuration
See `nvim/CLAUDE.md` for detailed Neovim-specific guidance including:
- `stylua .` - Format Lua code
- `:Lazy` commands for plugin management

### Configuration Testing
- Restart applications after making changes to test configurations
- For SketchyBar: `brew services restart sketchybar`
- For AeroSpace: restart or reload with AeroSpace commands

### Script Management
Utility scripts in `scripts/` directory:
- `float_ghostty.sh` - Create floating Ghostty terminal windows
- `float_qutebrowser.sh` - Create floating Qutebrowser windows

## Configuration Notes

- Zed editor is configured with vim mode enabled and system theme switching
- Terminal configurations prioritize Nerd Font support (BlexMono, Hack Nerd Font)
- All configurations assume macOS environment with Homebrew package management
- Window management relies on AeroSpace + SketchyBar integration for workspace awareness