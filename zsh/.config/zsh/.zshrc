# Interactive shell entry point. ZDOTDIR is set in ~/.zshenv, so zsh finds this
# file at $XDG_CONFIG_HOME/zsh/.zshrc.

# Startup profiling: ZSH_PROFILE=1 zsh -i -c exit
(( ${+ZSH_PROFILE} )) && zmodload zsh/zprof

# These are shell-internal, not for child processes, so they are not exported.
ZSH_CONF_DIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
ZSH_INIT=$ZSH_CONF_DIR/init.zsh

source $ZSH_INIT
