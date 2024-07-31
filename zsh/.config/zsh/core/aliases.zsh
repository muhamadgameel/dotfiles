# Listing Files
case $(uname) in
Darwin)
	alias ls="ls -hG"
	;;
Linux)
	alias ls="ls -h --color"
	;;
esac
alias l="ls"
alias la="ls -a"
alias ll="ls -l"
alias lla="ls -la"
alias mkdir="mkdir -p"

# kitty terminal add-ons commands
if (( $+commands[kitty] )); then
  alias icat="kitty +kitten icat"  # show image in terminal
  alias diff="kitty +kitten diff"  # diff between files
fi

# Resources Management
alias df='df -h'
alias du='du -h'

# Grep
alias grep="grep --color -i"

# Apps
alias v="nvim"
