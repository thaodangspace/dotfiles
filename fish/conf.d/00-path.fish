# Homebrew (arm64) — sets PATH, MANPATH, INFOPATH, HOMEBREW_*
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end

# Language / tool bin dirs, highest priority last-listed wins the front.
# -g = global (not universal, so it re-derives cleanly each session)
# -P = operate on $PATH directly rather than $fish_user_paths
fish_add_path -gP \
    /opt/homebrew/opt/php@8.4/sbin \
    /opt/homebrew/opt/php@8.4/bin \
    $HOME/.lmstudio/bin \
    $HOME/.opencode/bin \
    $HOME/.cargo/bin \
    $HOME/.bun/bin \
    $HOME/go/bin \
    $HOME/.local/bin

set -gx BUN_INSTALL $HOME/.bun

# OrbStack CLI integration
test -f $HOME/.orbstack/shell/init2.fish
and source $HOME/.orbstack/shell/init2.fish 2>/dev/null
