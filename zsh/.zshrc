export ZSH_CONF_DIR=~/.config/zsh
export ZSH_CACHE_DIR=~/.cache/zsh
export ZSH_INIT=$ZSH_CONF_DIR/init.zsh
export STARSHIP_CONFIG=~/.config/starship.toml
export STARSHIP_CACHE=~/.cache/starship

# Create the cache folder
mkdir -p $ZSH_CACHE_DIR
mkdir -p $STARSHIP_CACHE

source $ZSH_INIT
