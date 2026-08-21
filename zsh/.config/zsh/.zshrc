# Interactive shell entry point. ZDOTDIR is set in ~/.zshenv, so zsh finds this
# file at $XDG_CONFIG_HOME/zsh/.zshrc.

# Startup profiling: ZSH_PROFILE=1 zsh -i -c exit
(( ${+ZSH_PROFILE} )) && zmodload zsh/zprof

# These are shell-internal, not for child processes, so they are not exported.
ZSH_CONF_DIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
ZSH_INIT=$ZSH_CONF_DIR/init.zsh

# Starship reads these from the environment, so they do need exporting.
export STARSHIP_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml
export STARSHIP_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/starship

# Create cache folders (only if missing)
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR
[[ -d $STARSHIP_CACHE ]] || mkdir -p $STARSHIP_CACHE

source $ZSH_INIT
