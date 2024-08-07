# Android SDK
if [[ -z $ANDROID_HOME ]]; then
  case $(uname) in
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
  # TODO this should be more dynamic
  export PATH=$PATH:$ANDROID_HOME/build-tools/31.0.0/
fi

# FNM (Node package manager)
eval "$(fnm env --use-on-cd)"

# Apps
export PAGER=less
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty
