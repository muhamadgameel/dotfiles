# Treat these characters as part of a word.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

# Disable ^S/^Q start-stop output control so those keys are free for the line editor.
unsetopt flow_control

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
    # ^[OD / ^[OC are deliberately absent: in application mode those are the
    # *plain* Left/Right arrows, not Ctrl-modified ones. ESC-prefixed forms
    # (^[^[[D) belong to Alt below.
    'Control+Left'    $'^[[1;5D ^[[5D'
    'Control+Right'   $'^[[1;5C ^[[5C'
    'Alt+Up'          $'^[[1;3A ^[^[[A ^[[1;9A'
    'Alt+Left'        $'^[[1;3D ^[^[[D ^[[1;9D'
    'ControlPageUp'   $'^[[5;5~'
    'ControlPageDown' $'^[[6;5~'
    'Escape'          $'^['
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
    'Down'            "${terminfo[kcud1]}"
    'BackTab'         "${terminfo[kcbt]}"
  )

  # terminfo is empty for unknown/dumb TERMs, which previously made every
  # binding below fail with "cannot bind to an empty key sequence". Fall back to
  # the standard xterm sequences for anything terminfo did not supply.
  local -A fallback=(
    'F1' $'^[OP'   'F2' $'^[OQ'    'F3' $'^[OR'    'F4' $'^[OS'
    'F5' $'^[[15~' 'F6' $'^[[17~'  'F7' $'^[[18~'  'F8' $'^[[19~'
    'F9' $'^[[20~' 'F10' $'^[[21~' 'F11' $'^[[23~' 'F12' $'^[[24~'
    'Insert' $'^[[2~' 'Home' $'^[[H' 'End' $'^[[F'
    'PageUp' $'^[[5~' 'PageDown' $'^[[6~'
    'Up' $'^[[A' 'Down' $'^[[B'
    'BackTab' $'^[[Z'
  )
  local k
  for k in ${(k)fallback}; do
    [[ -z ${key_info[$k]} ]] && key_info[$k]=${fallback[$k]}
  done

  # Application mode (smkx, enabled by zle-line-init below) makes the cursor
  # keys send ^[O_ while normal mode sends ^[[_. terminfo reports whichever the
  # terminal uses; key_alt holds the other form so both can be bound.
  #
  # These stay in caret notation on purpose -- bindkey parses "^[" itself. Do
  # not compare them against the raw escape strings terminfo returns: inside
  # $'...' a "^[" is a literal caret plus bracket, not ESC, so such a
  # comparison never matches.
  typeset -gA key_alt
  key_alt=(
    'Up' '^[[A' 'Down' '^[[B'
    'Home' '^[[H' 'End' '^[[F'
  )
}

# Bind a widget to every non-empty sequence it is given, so a missing terminfo
# entry degrades to "one fewer binding" instead of an error at startup.
function bindkey-seq {
  local widget=$1 seq
  shift
  for seq in "$@"; do
    [[ -n $seq ]] && bindkey -M emacs "$seq" "$widget"
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
  # Reset keymaps to default first
  bindkey -d

  # Disable unbound keys that insert tilde
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
  local keymap key
  for keymap in $unbound_keys; do
    [[ -n $keymap ]] && bindkey -M emacs "${keymap}" _zle-noop
  done

  # Ctrl+Left and Ctrl+Right bindings to forward/backward word
  bindkey-seq backward-word ${(s: :)key_info[Control+Left]}
  bindkey-seq forward-word  ${(s: :)key_info[Control+Right]}

  # Kill to the beginning of the line.
  for key in $key_info[Escape]{K,k}; do
    bindkey -M emacs "$key" backward-kill-line
  done

  # Edit command in an external editor.
  bindkey -M emacs "$key_info[Control]X$key_info[Control]E" edit-command-line

  # Home, End (both normal and application-mode sequences)
  bindkey-seq beginning-of-line "$key_info[Home]" "$key_alt[Home]"
  bindkey-seq end-of-line       "$key_info[End]"  "$key_alt[End]"

  # Delete character
  bindkey-seq delete-char "$key_info[Delete]"

  # Expand history on space.
  bindkey -M emacs ' ' magic-space

  # Duplicate the previous word.
  for key in $key_info[Escape]{M,m}; do
    bindkey -M emacs "$key" copy-prev-shell-word
  done

  # Use a more flexible push-line.
  for key in $key_info[Escape]{q,Q}; do
    bindkey -M emacs "$key" push-line-or-edit
  done

  # Bind Shift + Tab to go to the previous menu item.
  bindkey-seq reverse-menu-complete "$key_info[BackTab]"

  # Expand command name to full path.
  for key in $key_info[Escape]{E,e}; do
    bindkey -M emacs "$key" expand-cmd-path
  done

  # control-space expands all aliases, including global
  bindkey -M emacs "$key_info[Control] " glob-alias

  # Directory navigation on Alt+Up / Alt+Left.
  bindkey-seq cd-up   ${(s: :)key_info[Alt+Up]}
  bindkey-seq cd-back ${(s: :)key_info[Alt+Left]}

  # Set Emacs mode
  bindkey -e
}
