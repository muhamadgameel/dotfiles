# Apps
export PAGER=less
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty

# Android SDK
if [[ -z $ANDROID_HOME ]]; then
  case $(uname) in
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
  
  # TODO this should be more dynamic
  export PATH=$PATH:$ANDROID_HOME/build-tools/35.0.0/
fi

# FNM (Node versions manager)
case $(uname) in
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

# Append to PATH
case $(uname) in
  Linux)
    export PATH=$HOME/.local/bin:$HOME/.cargo/bin:$PATH
    ;;
esac
