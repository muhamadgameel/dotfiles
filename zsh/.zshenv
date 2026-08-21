# This is the only zsh file that has to live in $HOME -- zsh always reads
# ~/.zshenv first. Its single job is to point ZDOTDIR at the real config so
# everything else can live under XDG_CONFIG_HOME.
#
# Keep this file minimal and side-effect free: it is sourced by *every* zsh,
# including non-interactive ones invoked by scripts and editors.

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

export ZDOTDIR=$XDG_CONFIG_HOME/zsh
