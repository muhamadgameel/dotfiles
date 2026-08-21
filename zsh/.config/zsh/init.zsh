# ZSH_CONF_DIR is already set by .zshrc; derive it from this file's own path so
# init.zsh also works when sourced directly.
typeset -g ZSH_CONF_DIR=${0:a:h}

# Load custom completions
fpath+=$ZSH_CONF_DIR/completions

# Load custom functions
fpath+=$ZSH_CONF_DIR/functions
# (N) so an empty functions/ directory is not a startup error.
autoload -Uz -- "$ZSH_CONF_DIR"/functions/[^_]*(N:t)

# Load configs.
#
# Order matters: settings first (options everything else assumes), then input,
# aliases and env. Completion is deliberately loaded *after* the plugins below
# so that plugins contributing to $fpath are registered before compinit runs.
sources=(
  "settings"
  "cache"
  "input"
  "aliases"
  "env"
  "fzf"
)

for src in ${sources[@]}; do
  source $ZSH_CONF_DIR/core/$src.zsh
done
unset src sources

# load Zpm package manager
source $ZSH_CONF_DIR/zpm.zsh

# Plugins that add completions must load before compinit.
Plug "zsh-users/zsh-completions"

# Completion system (compinit). Everything above has finished touching $fpath.
source $ZSH_CONF_DIR/core/completion.zsh

# fzf-tab must come after compinit and before any plugin that wraps ZLE widgets.
Plug "Aloxaf/fzf-tab"

# Remaining plugins. fast-syntax-highlighting wraps widgets and must stay last.
Plug "zsh-users/zsh-autosuggestions"
Plug "zsh-users/zsh-history-substring-search"
Plug "zdharma-continuum/fast-syntax-highlighting"

# History substring search. Bind both the normal and application-mode cursor
# sequences so this works regardless of terminfo/smkx state.
bindkey-seq history-substring-search-up   "$key_info[Up]"   "$key_alt[Up]"
bindkey-seq history-substring-search-down "$key_info[Down]" "$key_alt[Down]"

# Auto Suggestions (fall back to completion engine when history has no match)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Rebind widgets once at startup instead of on every precmd -- a measurable
# startup and per-prompt saving. Safe as long as no widget is defined later.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Load starship Prompt (cached; see core/cache.zsh)
cached-eval starship starship init zsh

# Startup profiling: ZSH_PROFILE=1 zsh -i -c exit
(( ${+ZSH_PROFILE} )) && zprof
