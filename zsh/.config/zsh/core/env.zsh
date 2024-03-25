# Android SDK
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

# NVM
case `uname` in
  Darwin)
    export NVM_DIR=$HOME/.nvm
    local nvm_init=$(brew --prefix nvm)/nvm.sh
    [[ -s $nvm_init ]] && source $nvm_init
  ;;
esac

# Apps
export PAGER=less
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=kitty
