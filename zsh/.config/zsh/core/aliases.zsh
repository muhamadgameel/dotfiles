# Listing Files
case $_os in
  Darwin)
    alias ls="ls -hG"
    ;;
  Linux)
    alias ls="ls -h --color"
    ;;
esac
alias l="ls"
alias la="ls -A"
alias ll="ls -l"
alias lla="ls -lA"

if (( $+commands[eza] )); then
  alias ls="eza --color=always --icons=always --smart-group"
  alias ll="ls --long"
  alias la="ls --all"
  alias lla="ls --long --all"
fi

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
  alias cd="z"
fi

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# File and directory operations
alias mkdir="mkdir -pv" # -p creates parent dirs, -v for verbose
alias cp="cp -iv"       # Confirm before overwriting
alias mv="mv -iv"       # Confirm before overwriting

# Resources Management
alias df='df -h'
alias du='du -h'

# Grep
alias grep="grep --color=auto -i"

# Viewers
if (( $+commands[bat] )); then
  alias cat="bat"
fi

# Process management
alias psa="ps aux"
alias psg="pgrep -af"

# Apps
alias v="nvim"
alias g="git"
alias py="python3"

# Network
alias myip="curl https://ipecho.net/plain; echo"

case $_os in
  Darwin)
    alias ports="netstat -vanp tcp && netstat -vanp udp"
    alias psport="lsof -iTCP -sTCP:LISTEN -P -n"
    ;;
  Linux)
    alias ports="ss -tulan"
    alias psport="ss -tlnp"
    ;;
esac

# System
case $_os in
  Darwin)
    alias sys-update="softwareupdate -i -a"
    ;;
  Linux)
    if [ -f /etc/os-release ]; then
      OS_ID=$(. /etc/os-release && echo $ID)
      case $OS_ID in
        debian | ubuntu | elementary | pop)
          alias sys-update="sudo apt update && sudo apt upgrade"
          ;;
        arch | manjaro)
          alias sys-update="sudo pacman -Syu"
          ;;
        esac
    fi
    ;;
esac

# Help (man pages for builtins)
autoload -Uz run-help
(( ${+aliases[run-help]} )) && unalias run-help
alias help="run-help"

# Misc
alias h="history"
alias j="jobs -l"
alias path='echo $PATH | tr ":" "\n"'
alias now="date +\"%T\""
alias nowdate="date +\"%d-%m-%Y\""
