# fzf configuration.
#
# Sourced from init.zsh. Everything here is guarded so the file is inert when
# fzf is not installed.

(( $+commands[fzf] )) || return 0

# ===== Sources
# Prefer fd: it honours .gitignore, is faster than find, and gets hidden files
# right. Falls back to fzf's built-in walker when fd is missing.
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# ===== Appearance and behaviour
export FZF_DEFAULT_OPTS="
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='  '
  --pointer='▶'
  --marker='✓'
  --cycle
  --multi
  --scrollbar='│'
  --bind='ctrl-/:toggle-preview'
  --bind='alt-up:preview-half-page-up'
  --bind='alt-down:preview-half-page-down'
  --bind='alt-a:toggle-all'
"

# ===== Previews
if (( $+commands[bat] )); then
  export FZF_CTRL_T_OPTS="
    --preview 'bat --style=numbers --color=always --line-range=:200 {} 2>/dev/null || eza --tree --level=2 --color=always --icons=always {} 2>/dev/null'
    --preview-window='right:60%:wrap'
  "
fi

if (( $+commands[eza] )); then
  export FZF_ALT_C_OPTS="
    --preview 'eza --tree --level=2 --color=always --icons=always {}'
    --preview-window='right:60%'
  "
fi

# Ctrl+R: show the full command in a preview pane, since long pipelines get
# truncated in the result list.
#
# Built by appending rather than with a nested ${var:+...} expansion: fzf's
# {2..} placeholder ends in a brace, which such an expansion would swallow, and
# backslash-escaped quotes stay literal inside double quotes -- either one makes
# fzf reject the whole string with "invalid command line string".
FZF_CTRL_R_OPTS="--preview 'echo {2..}'"
FZF_CTRL_R_OPTS+=" --preview-window='down:3:hidden:wrap'"
FZF_CTRL_R_OPTS+=" --bind='?:toggle-preview'"

_fzf_clip=''
if (( $+commands[wl-copy] )); then
  _fzf_clip='wl-copy'
elif (( $+commands[pbcopy] )); then
  _fzf_clip='pbcopy'
elif (( $+commands[xclip] )); then
  _fzf_clip='xclip -selection clipboard'
fi

if [[ -n $_fzf_clip ]]; then
  FZF_CTRL_R_OPTS+=" --bind='ctrl-y:execute-silent(echo -n {2..} | $_fzf_clip)+abort'"
  FZF_CTRL_R_OPTS+=" --header='Ctrl+Y to copy the command'"
fi
unset _fzf_clip
export FZF_CTRL_R_OPTS

# ===== Key bindings and completion
# fzf 0.48+ ships its shell integration behind `fzf --zsh`.
source <(fzf --zsh)
