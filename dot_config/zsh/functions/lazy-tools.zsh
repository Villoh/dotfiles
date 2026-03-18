#!/usr/bin/env zsh
# Lazy-load heavy tools to speed up shell startup

# pyenv — inicializa solo al primer uso
pyenv() {
    unfunction pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(command pyenv init - zsh)"
    pyenv "$@"
}

# brew — inicializa solo al primer uso
brew() {
    unfunction brew
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
    brew "$@"
}
