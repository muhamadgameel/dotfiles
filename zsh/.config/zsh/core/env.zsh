# Android SDK
# TODO enable if find android files
if [[ -z $ANDROID_HOME ]]; then
  case `uname` in
    Darwin)
      export ANDROID_HOME=$HOME/Library/Android/sdk
    ;;
    Linux)
      export ANDROID_HOME=/opt/android-sdk
    ;;
  esac

  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/tools
  export PATH=$PATH:$ANDROID_HOME/tools/bin
  export PATH=$PATH:$ANDROID_HOME/platform-tools
fi

# FNM (Node package manager)
if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd)"
fi

# Apps
export PAGER=less
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty
