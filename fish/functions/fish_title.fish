# Always show the working directory in the terminal tab/window title,
# instead of the running process (replaces DISABLE_AUTO_TITLE + the
# precmd/preexec hooks from .zshrc).
function fish_title
    prompt_pwd
end
