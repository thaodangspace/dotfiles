# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a LazyVim configuration for Neovim located at `~/.config/nvim/`. LazyVim is a plugin distribution that provides a modern, well-configured Neovim setup with sensible defaults.

### Core Structure

- `init.lua` - Entry point that bootstraps the configuration by requiring `config.lazy`
- `lua/config/lazy.lua` - Main Lazy.nvim plugin manager setup that:
  - Installs Lazy.nvim if not present
  - Configures LazyVim as the base distribution
  - Imports custom plugins from the `plugins/` directory
  - Sets up performance optimizations and plugin checking
- `lua/config/` - Configuration modules for options, keymaps, and autocmds
- `lua/plugins/` - Custom plugin specifications that extend or override LazyVim defaults

### Plugin Management

Uses Lazy.nvim as the plugin manager with LazyVim as the base distribution. The configuration follows LazyVim's modular approach where:
- Base LazyVim plugins are imported automatically
- Custom plugins are defined in `lua/plugins/` directory
- Plugin specifications can override or extend LazyVim defaults
- Mason is used for automatic tool installation (LSP servers, formatters, linters)

### Key Configuration Files

- `lua/config/options.lua` - Neovim options (currently minimal, relies on LazyVim defaults)
- `lua/config/keymaps.lua` - Key mappings (currently minimal, relies on LazyVim defaults)
- `lua/plugins/example.lua` - Example plugin configurations (disabled by default)
- `stylua.toml` - Lua formatter configuration (2-space indentation, 120 column width)

## Development Commands

### Code Formatting
- `stylua .` - Format Lua code using the project's stylua configuration
- Configuration: 2-space indentation, 120 character line width

### Plugin Management
- `:Lazy` - Open Lazy.nvim plugin manager UI
- `:Lazy update` - Update all plugins
- `:Lazy clean` - Remove unused plugins
- `:Lazy check` - Check for plugin updates

### LSP and Tools
- Mason automatically installs: stylua, shellcheck, shfmt, flake8
- LSP servers are configured through LazyVim's LSP setup
- Use `:Mason` to manage installed tools

## Common Configurations

### Snacks Terminal Float
To add floating terminal support via Snacks.nvim, create a plugin file in `lua/plugins/` with:
```lua
return {
  "folke/snacks.nvim",
  opts = {
    terminal = {
      float = {
        enabled = true,
        -- Float window configuration
        relative = "editor",
        row = 0.1,
        col = 0.1,
        width = 0.8,
        height = 0.8,
        border = "rounded",
        title = " Terminal ",
        title_pos = "center",
      },
    },
  },
  keys = {
    { "<leader>t", function() Snacks.terminal.toggle() end, desc = "Toggle Terminal" },
  },
}
```

## Development Notes

- The example plugin file is disabled by default (`if true then return {} end`)
- Custom plugins should be added to `lua/plugins/` as separate files
- LazyVim provides extensive defaults - check LazyVim documentation before overriding
- Plugin specifications support both simple and complex configurations with opts functions