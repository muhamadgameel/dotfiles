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
  # --cmd cd makes zoxide define a real `cd` function rather than aliasing it.
  eval "$(zoxide init zsh --cmd cd)"
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
alias grep="grep --color=auto"

# System Monitoring
if (( $+commands[btop] )); then
  alias top="btop"
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
    # Read ID= straight out of /etc/os-release. The previous
    # `$(. /etc/os-release && echo $ID)` spawned a subshell on every startup and
    # leaked $OS_ID into the global namespace.
    if [[ -r /etc/os-release ]]; then
      typeset -a _osrelease_id
      _osrelease_id=(${(M)${(f)"$(</etc/os-release)"}:#ID=*})
      case ${${_osrelease_id[1]#ID=}//\"/} in
        debian | ubuntu | elementary | pop)
          alias sys-update="sudo apt update && sudo apt upgrade"
          ;;
        arch | manjaro | endeavouros | cachyos)
          alias sys-update="sudo pacman -Syu"
          ;;
        fedora | rhel | centos)
          alias sys-update="sudo dnf upgrade --refresh"
          ;;
      esac
      unset _osrelease_id
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
