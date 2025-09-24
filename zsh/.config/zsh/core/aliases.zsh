# Cache OS detection
local _os=$(uname)

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
alias la="ls -A" # -A shows almost all (excludes . and ..)
alias ll="ls -l"
alias lla="ls -lA"
alias lr="ls -R"    # Recursive ls
alias lt="ls -lt"   # Sort by newest first
alias lS="ls -1FSs" # Sort by size

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# File and directory operations
alias mkdir="mkdir -pv" # -p creates parent dirs, -v for verbose
alias rm="rm -i"        # Interactive removal
alias cp="cp -i"        # Interactive copy
alias mv="mv -i"        # Interactive move

# kitty terminal add-ons commands
if (( $+commands[kitty] )); then
  alias icat="kitty +kitten icat" # show image in terminal
  alias diff="kitty +kitten diff" # diff between files
  alias ssh="kitty +kitten ssh"   # Better SSH support in kitty
fi

# Resources Management
alias df='df -h'
alias du='du -h'

# Grep
alias grep="grep --color=auto -i"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"

# Viewers
if (( $+commands[bat] )); then
  alias cat="bat"
fi

# Process management
alias psa="ps aux"
alias psg="ps aux | grep"

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
        *)
          echo "Unsupported Linux distribution for update alias"
          ;;
      esac
    else
      echo "Unable to determine Linux distribution for update alias"
    fi
    ;;
esac

# Misc
alias h="history"
alias j="jobs -l"
alias path='echo $PATH | tr ":" "\n"'
alias now="date +\"%T\""
alias nowdate="date +\"%d-%m-%Y\""
