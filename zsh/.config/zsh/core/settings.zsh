autoload -Uz zmv

# Cache OS detection globally (used by aliases.zsh, env.zsh).
# $OSTYPE is a zsh builtin parameter, so this costs no fork.
case $OSTYPE in
  linux*)  typeset -g _os=Linux ;;
  darwin*) typeset -g _os=Darwin ;;
  *)       typeset -g _os=${(C)OSTYPE%%[0-9.]*} ;;
esac

# ===== Basics
setopt no_beep              # do not beep on error
setopt interactive_comments # Enable comments in interactive shell.
unsetopt clobber            # Do not overwrite existing files with > and >>.  Use >! and >>! to bypass.

# ===== Changing Directories
setopt auto_cd           # Auto changes to a directory without typing cd.
setopt auto_pushd        # cd automatically pushes old dir onto dir stack
setopt pushd_ignore_dups # No duplicate entries in dir stack
setopt pushd_silent      # Don't print dir stack after pushd/popd

# ===== Expansion and Globbing
setopt extended_glob # Use extended globbing syntax.

# ===== Printing
setopt brace_ccl       # Allow brace character class list expansion, echo {abc.}file
setopt combining_chars # Combine zero-length punctuation characters (accents) with the base character
setopt rc_quotes       # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'.

# ===== Jobs
setopt long_list_jobs # List jobs in the long format by default.
setopt auto_resume    # Resume existing job from background before creating a new process by typing its name
setopt notify         # Report status of background jobs immediately
unsetopt bg_nice      # Do not run all background jobs at a lower priority
unsetopt hup          # Do not kill jobs on shell exit

# ===== Prompt
setopt prompt_subst      # Enable parameter expansion, command substitution, and arithmetic expansion in the prompt
setopt transient_rprompt # only show the rprompt on the current prompt

# ===== Pager
export LESS="--raw-control-chars --use-color --quit-if-one-screen --no-init"

# ===== Locale
# Only LANG is set on purpose: LC_ALL overrides every LC_* category and cannot
# be selectively undone, which breaks per-category overrides like LC_TIME.
export LANG=en_US.UTF-8

# ===== History
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=$ZSH_CACHE_DIR/zsh_history

setopt bang_hist              # Treat the '!' character specially during expansion
setopt extended_history       # Write the history file in the ":start:elapsed;command" format
setopt share_history          # Share history between all sessions (implies inc_append_history_time)
setopt hist_expire_dups_first # Delete duplicates first when HISTFILE size exceeds HISTSIZE.
setopt hist_ignore_all_dups   # Delete old recorded entry if new entry is a duplicate (implies hist_ignore_dups)
setopt hist_fcntl_lock        # Use fcntl locking on the history file; safer with many concurrent shells
setopt hist_ignore_space      # Ignore commands that start with space
setopt hist_save_no_dups      # Do not write duplicate entries in the history file
setopt hist_verify            # Show command with history expansion to user before running it
setopt hist_find_no_dups      # When searching history do not display results already cycled through twice
setopt hist_reduce_blanks     # Remove extra blanks from each command line being added to history

# Lists the 10 most used commands
alias history-stat="history 0 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head"
