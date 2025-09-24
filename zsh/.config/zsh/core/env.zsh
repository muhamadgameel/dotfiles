# Apps
export PAGER=less
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty

# Fix GPG in terminal
export GPG_TTY=$(tty)

# Cache OS detection
local _os=$(uname)

# Android SDK
if [[ -z $ANDROID_HOME ]]; then
  case $_os in
    Darwin)
      export ANDROID_HOME=$HOME/Library/Android/sdk
      ;;
    # TODO this could be different for other distributions
    Linux)
      export ANDROID_HOME=$HOME/Android/Sdk
      ;;
  esac

  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/platform-tools
  
  # Use latest build-tools version if available
  if [[ -d "$ANDROID_HOME/build-tools" ]]; then
    local latest_build_tools=$(ls "$ANDROID_HOME/build-tools" | sort -V | tail -n1)
    [[ -n "$latest_build_tools" ]] && export PATH=$PATH:$ANDROID_HOME/build-tools/$latest_build_tools
  fi
fi

# Append to PATH
case $_os in
  Darwin)
    eval "$(/opt/homebrew/bin/brew shellenv)"
    . "$HOME/.cargo/env"
    ;;
  Linux)
    export PATH=$HOME/.local/bin:$HOME/.cargo/bin:$PATH
    ;;
esac

# FNM (Node versions manager)
case $_os in
  Darwin)
    if (( $+commands[fnm] )) then
      eval "$(fnm env --use-on-cd)"
    fi
    ;;
  Linux)
    FNM_PATH=$HOME/.local/share/fnm
    if [ -d "$FNM_PATH" ]; then
      export PATH=$HOME/.local/share/fnm:$PATH
      eval "$(fnm env --use-on-cd)"
    fi
    ;;
esac