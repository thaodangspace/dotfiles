# dotfiles

## Stow

```shell
stow -t ~/.config/nvim nvim
stow -t ~/.config/ghostty ghostty
stow -t ~/.config/scripts scripts
stow -t ~/.config/kitty kitty
stow -t ~/.qutebrowser qutebrowser
mkdir -p ~/.config/yabai ~/.config/skhd
stow -t ~/.config/yabai yabai
stow -t ~/.config/skhd skhd
stow -t ~ aerospace   # legacy fallback, not used with yabai
stow -t ~ zsh
stow -t ~ wezterm
stow -t ~ tmux
stow -t ~/.claude/commands commands
stow -t ~/.pi/agent/prompts commands
```

### yabai + skhd (window manager)

```shell
brew install asmvik/formulae/yabai asmvik/formulae/skhd jq
mkdir -p ~/.config/yabai ~/.config/skhd
stow -t ~/.config/yabai yabai
stow -t ~/.config/skhd skhd
yabai --start-service
skhd --start-service
# grant Accessibility to both when macOS asks, then:
yabai --restart-service; skhd --reload
# enable the native ctrl-1..9 "Switch to Desktop" shortcuts (alt-N falls back to them)
yabai/enable-desktop-hotkeys.sh
```

SIP is partially disabled and the scripting addition is loaded (instant space
switching, no animation). On macOS 27 this needs a fork build of yabai until an
official release supports it; after any yabai binary change re-run
`yabai/update-sudoers.sh` and re-add yabai in Accessibility. Details, recovery
steps and checks: `yabai/README.md`. Bindings are the same as the old AeroSpace
config: `alt-h/j/k/l` focus, `alt-shift-h/j/k/l` move, `alt-N` / `alt-shift-N`
spaces, `alt-shift-f` fullscreen, `alt-shift-space` float, `alt-shift-;` service
mode. Apps without a rule in `yabairc` are routed to space 7 (`yabai/route.sh`).

### Fish

`~/.config/fish` must contain real (non-symlinked) `conf.d/`, `functions/` and
`completions/` directories so stow links individual files into them — that keeps
fisher-managed plugin files out of this repo:

```shell
mkdir -p ~/.config/fish/{conf.d,functions,completions}
stow -t ~/.config/fish fish
```

## Fish shell

```shell
brew install fish

# Allow fish as a login shell, then switch to it
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

# Fisher (plugin manager) — reads fish/fish_plugins and installs Tide with it
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish |
    source && fisher install jorgebucaran/fisher

# Tide prompt configuration (universal vars aren't tracked by stow)
fish fish/tide-setup.fish
```

Revert to zsh with `chsh -s /bin/zsh`.

| file | purpose |
| --- | --- |
| `fish/config.fish` | interactive-only setup; keep it small |
| `fish/conf.d/00-path.fish` | `brew shellenv`, PATH, OrbStack |
| `fish/conf.d/10-aliases.fish` | aliases |
| `fish/functions/fish_title.fish` | show pwd in the tab title |
| `fish/fish_plugins` | fisher manifest — `fisher update` installs from it |
| `fish/tide-setup.fish` | reproduces the Tide prompt non-interactively |
