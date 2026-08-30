# ~/.config/fish/config.fish  (stow: fish -> ~/.config/fish)
#
# Load order: conf.d/*.fish (alphabetical) -> config.fish -> interactive setup
# Keep this file small; put topical config in conf.d/.

if status is-interactive
    # Fish has autosuggestions + syntax highlighting built in (no plugin needed).
    set -g fish_greeting

    # Vi-ish nicety: keep emacs bindings but drop ctrl-k, which used to
    # clear the terminal by accident (mirrors `bindkey -r '^K'` from zsh).
    bind --erase \ck 2>/dev/null
end
