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

# Resources Management
alias df='df -h'
alias du='du -h'

# Grep
alias grep="grep --color=auto -i"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"

# Process management
alias psa="ps aux"
alias psg="ps aux | grep"
# Apps
alias v="nvim"
alias g="git"
alias py="python3"

# Misc
alias h="history"
alias j="jobs -l"
alias path='echo $PATH | tr ":" "\n"'
alias now="date +\"%T\""
alias nowdate="date +\"%d-%m-%Y\""
