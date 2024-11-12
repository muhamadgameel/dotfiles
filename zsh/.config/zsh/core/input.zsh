# Treat these characters as part of a word.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

zmodload zsh/terminfo
zmodload zsh/zle
zmodload zsh/parameter  # For more efficient parameter handling

autoload -Uz edit-command-line
zle -N edit-command-line

# Use an anonymous function for initialization
() {
  typeset -gA key_info
  key_info=(
    'Control'         $'^'
    'Control+Left'    $'^[[1;5D ^[[5D ^[^[[D ^[OD'
    'Control+Right'   $'^[[1;5C ^[[5C ^[^[[C ^[OC'
    'ControlPageUp'   $'^[[5;5~'
    'ControlPageDown' $'^[[6;5~'
    'Escape'          $'^['
    'Meta'            $'\M-'
    'Backspace'       $'^?'
    'Delete'          $'^[[3~'
    'F1'              "${terminfo[kf1]}"
    'F2'              "${terminfo[kf2]}"
    'F3'              "${terminfo[kf3]}"
    'F4'              "${terminfo[kf4]}"
    'F5'              "${terminfo[kf5]}"
    'F6'              "${terminfo[kf6]}"
    'F7'              "${terminfo[kf7]}"
    'F8'              "${terminfo[kf8]}"
    'F9'              "${terminfo[kf9]}"
    'F10'             "${terminfo[kf10]}"
    'F11'             "${terminfo[kf11]}"
    'F12'             "${terminfo[kf12]}"
    'Insert'          "${terminfo[kich1]}"
    'Home'            "${terminfo[khome]}"
    'End'             "${terminfo[kend]}"
    'PageUp'          "${terminfo[kpp]}"
    'PageDown'        "${terminfo[knp]}"
    'Up'              "${terminfo[kcuu1]}"
    'Left'            "${terminfo[kcub1]}"
    'Down'            "${terminfo[kcud1]}"
    'Right'           "${terminfo[kcuf1]}"
    'BackTab'         "${terminfo[kcbt]}"
  )
}

function bindkey-all {
  local keymap
  for keymap in $(bindkey -l); do
    if [[ "$#" -eq 0 ]]; then
      print -P "%F{blue}#### %f%F{green}${keymap}%f" >&2
      bindkey -M "${keymap}"
    else
      bindkey -M "${keymap}" "$@"
    fi
  done
}

# Enables terminal application mode
function zle-line-init() {
  (( ${+terminfo[smkx]} )) && echoti smkx
}
zle -N zle-line-init

# Disables terminal application mode
function zle-line-finish() {
  (( ${+terminfo[rmkx]} )) && echoti rmkx
}
zle -N zle-line-finish

# Expand aliases
function glob-alias {
  zle _expand_alias
  zle expand-word
  zle magic-space
}
zle -N glob-alias

# Up (cd ..)
function cd-up() {
  [[ $PWD != / ]] && pushd .. > /dev/null
  zle reset-prompt
}
zle -N cd-up

# Back (cd -)
function cd-back() {
  popd -q &> /dev/null
  zle reset-prompt
}
zle -N cd-back

# Unbound keys insert a tilde, disable them
function _zle-noop { : }
zle -N _zle-noop

# Use an anonymous function for key binding
() {
  local -a unbound_keys=(
    "${key_info[F1]}"
    "${key_info[F2]}"
    "${key_info[F3]}"
    "${key_info[F4]}"
    "${key_info[F5]}"
    "${key_info[F6]}"
    "${key_info[F7]}"
    "${key_info[F8]}"
    "${key_info[F9]}"
    "${key_info[F10]}"
    "${key_info[F11]}"
    "${key_info[F12]}"
    "${key_info[PageUp]}"
    "${key_info[PageDown]}"
    "${key_info[ControlPageUp]}"
    "${key_info[ControlPageDown]}"
    "${key_info[Insert]}"
  )
  for keymap in $unbound_keys; do
    bindkey -M emacs "${keymap}" _zle-noop
  done

  # Set default mode
  bindkey -d

  # Ctrl+Left and Ctrl+Right bindings to forward/backward word
  for key in ${(s: :)key_info[Control+Left]}; do
    bindkey -M emacs "$key" backward-word
  done
  for key in ${(s: :)key_info[Control+Right]}; do
    bindkey -M emacs "$key" forward-word
  done

  # Kill to the beginning of the line.
  for key in $key_info[Escape]{K,k}; do
    bindkey -M emacs "$key" backward-kill-line
  done

  # Edit command in an external editor.
  bindkey -M emacs "$key_info[Control]X$key_info[Control]E" edit-command-line

  # Home, End
  bindkey -M emacs "$key_info[Home]" beginning-of-line
  bindkey -M emacs "$key_info[End]" end-of-line

  # Delete character
  bindkey -M emacs "$key_info[Delete]" delete-char
  bindkey -M emacs "$key_info[Backspace]" backward-delete-char

  # Move character
  bindkey -M emacs "$key_info[Left]" backward-char
  bindkey -M emacs "$key_info[Right]" forward-char

  # Expand history on space.
  bindkey -M emacs ' ' magic-space

  # Clear screen.
  bindkey -M emacs "$key_info[Control]L" clear-screen

  # Duplicate the previous word.
  for key in $key_info[Escape]{M,m}; do
    bindkey -M emacs "$key" copy-prev-shell-word
  done

  # Use a more flexible push-line.
  for key in $key_info[Escape]{q,Q}; do
    bindkey -M emacs "$key" push-line-or-edit
  done

  # Bind Shift + Tab to go to the previous menu item.
  bindkey -M emacs "$key_info[BackTab]" reverse-menu-complete

  # Expand command name to full path.
  for key in $key_info[Escape]{E,e}; do
    bindkey -M emacs "$key" expand-cmd-path
  done

  # control-space expands all aliases, including global
  bindkey -M emacs "$key_info[Control] " glob-alias

  # cd ..
  bindkey -M emacs "${key_info[Control]}K" cd-up

  # cd -
  bindkey -M emacs "${key_info[Control]}J" cd-back

  # Set Emacs mode
  bindkey -e
}
