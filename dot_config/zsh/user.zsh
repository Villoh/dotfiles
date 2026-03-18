#  Startup 
# Commands to execute on startup (before the prompt is shown)
if [[ $- == *i* ]]; then
    if command -v pokego >/dev/null; then
        pokego --no-title -r 1,3,6
    elif command -v pokemon-colorscripts >/dev/null; then
        pokemon-colorscripts --no-title -r 1,3,6
    elif command -v fastfetch >/dev/null; then
        if do_render "image"; then
            fastfetch --logo-type kitty
        fi
    fi
fi

#  Overrides 
# HYDE_ZSH_NO_PLUGINS=1        # Set to 1 to disable loading of oh-my-zsh plugins
# unset HYDE_ZSH_PROMPT        # Disable HyDE's prompt and load your own
# HYDE_ZSH_COMPINIT_CHECK=1    # Set 24 (hours) per compinit security check

#  OMZ Plugins
if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    plugins=(
        "sudo"
    )
fi

#  Tools 

# fnm — Node version manager
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh --log-level=quiet)"

# Bun   
export BUN_INSTALL="$HOME/.local/share/bun"

# asdf — universal version manager
# Shims must be in PATH from the start so tools are resolved correctly
export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="${ASDF_DATA_DIR}/shims:$PATH"

# uv  — managed by uv's env script (handles PATH deduplication for both)
[[ -s "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Homebrew completions
fpath=("/home/linuxbrew/.linuxbrew/share/zsh/site-functions" $fpath)

# Aliases
alias zed='zeditor'
