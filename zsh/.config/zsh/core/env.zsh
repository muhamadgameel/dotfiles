# Keep $PATH and $fpath free of duplicates. zsh ties the `path`/`fpath` arrays
# to $PATH/$FPATH, so marking them unique here dedupes every later addition --
# including the ones re-sourced by nested interactive shells.
typeset -U path PATH fpath

# Apps
export PAGER=less
export EDITOR=nvim
export VISUAL=nvim
export TERMINAL=alacritty

# Colourised man pages via bat (replaces the old LESS_TERMCAP_* block)
if (( $+commands[bat] )); then
  export MANPAGER="sh -c 'col -bx | bat --language man --plain'"
  export MANROFFOPT="-c"
fi

# Fix GPG in terminal ($TTY is a zsh builtin parameter, so no `tty` fork)
export GPG_TTY=$TTY

# Android SDK
if [[ -z $ANDROID_HOME ]]; then
  case $_os in
    Darwin) export ANDROID_HOME=$HOME/Library/Android/sdk ;;
    # NOTE: this could be different for other distributions
    Linux)  export ANDROID_HOME=$HOME/Android/Sdk ;;
  esac
fi

# Add the SDK to $PATH whether or not ANDROID_HOME was already exported by the environment
if [[ -n $ANDROID_HOME && -d $ANDROID_HOME ]]; then
  path=(
    $ANDROID_HOME/emulator
    $ANDROID_HOME/platform-tools
    # Highest build-tools version, picked with a glob sorted numerically in descending order
    $ANDROID_HOME/build-tools/*(NOn/[1])
    $path
  )
fi

# Append to PATH
case $_os in
  Darwin)
    eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -r $HOME/.cargo/env ]] && . "$HOME/.cargo/env"
    ;;
  Linux)
    path=($HOME/.local/bin $HOME/.cargo/bin $path)
    ;;
esac

# FNM (Node versions manager)
if [[ $_os == Linux && -d $HOME/.local/share/fnm ]]; then
  path=($HOME/.local/share/fnm $path)
fi
# Deliberately NOT run through cached-eval: `fnm env` bakes a per-shell
# FNM_MULTISHELL_PATH under /run/user into its output, so a cached copy would
# point every later shell at a directory that no longer exists.
if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi
