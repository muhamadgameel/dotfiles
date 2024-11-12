# Load custom completions
fpath+=${0:a:h}/completions

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

# Auto Suggestions
ZSH_AUTOSUGGEST_STRATEGY=(history)

# Load starship Prompt
if (( $+commands[starship] )) then
  eval "$(starship init zsh)"
fi

