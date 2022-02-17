# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --ignore-file .gitignore'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--no-256"

# NVM
case `uname` in
  Darwin)
    export NVM_DIR=~/.nvm
    [[ -s $NVM_DIR/nvm.sh ]] && source $(brew --prefix nvm)/nvm.sh
  ;;
esac

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

# Java Fix for wayland (sway)
export _JAVA_AWT_WM_NONREPARENTING=1

# Pagers
export PAGER=less
export EDITOR=nvim
export VISUAL=nvim

# SSH Agent
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Apps
export WEB_BROWSER=brave
export TERMINAL=kitty
export FILE_MANAGER=pcmanfm
export TORRENT_CLIENT=transmission-gtk
export VOLUME_CONTROL=pavucontrol

# Volume Control CLI
if (( $+commands[pamixer] )); then
  export DEFAULT_VOLUME_INC="pamixer --allow-boost -i 5"
  export DEFAULT_VOLUME_DEC="pamixer --allow-boost -d 5"
  export DEFAULT_VOLUME_TOGGLE="pamixer --allow-boost -t"
fi
