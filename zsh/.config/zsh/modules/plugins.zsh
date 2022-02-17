# History substring search
bindkey "${key_info[Up]}" history-substring-search-up
bindkey "${key_info[Down]}" history-substring-search-down

# AutoSuggestions
ZSH_AUTOSUGGEST_USE_ASYNC=1
bindkey "${key_info[Control]}N" autosuggest-accept
