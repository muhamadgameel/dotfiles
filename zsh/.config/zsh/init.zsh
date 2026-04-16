# Load custom completions
fpath+=${0:a:h}/completions

# Load custom functions
fpath+=${0:a:h}/functions
autoload -Uz -- "${0:a:h}"/functions/[^_]*(:t)

# Load configs
sources=(
  "settings"
  "input"
  "aliases"
  "env"
  "completion"
)

for src in ${sources[@]}; do
  source ${0:a:h}/core/$src.zsh
done

# load Zpm package manager
source ${0:a:h}/zpm.zsh

# Add plugins
Plug "zdharma-continuum/fast-syntax-highlighting"
Plug "zsh-users/zsh-autosuggestions"
Plug "zsh-users/zsh-completions"
Plug "zsh-users/zsh-history-substring-search"

# History substring search
bindkey -M emacs "${key_info[Up]}" history-substring-search-up
bindkey -M emacs "${key_info[Down]}" history-substring-search-down

# Auto Suggestions (fall back to completion engine when history has no match)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# fzf integration (Ctrl+R history, Ctrl+T file finder, Alt+C cd)
if (( $+commands[fzf] )) then
  eval "$(fzf --zsh)"
fi

# Load starship Prompt
if (( $+commands[starship] )) then
  eval "$(starship init zsh)"
fi

