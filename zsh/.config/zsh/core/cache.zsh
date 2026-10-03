# Cached tool initialisation.
#
# `eval "$(tool init zsh)"` forks a process and regenerates byte-identical
# output on every single shell startup. Across starship, zoxide and fzf that
# measured ~17ms here. Cache the generated code to a file and source that
# instead -- sourcing a pre-compiled cache costs a fraction of the fork.
#
# The cache is invalidated when the tool's binary changes its modification time
# or the command line used to generate it changes, so upgrading, downgrading or
# reinstalling a tool, or editing its flags, picks up the new output.
#
# NOT everything is safe to cache: a tool whose output embeds per-session state
# must keep running live. fnm is the example -- `fnm env` bakes in a
# per-shell FNM_MULTISHELL_PATH under /run/user, and a cached copy would point
# every later shell at a directory that no longer exists.

: ${ZSH_CACHE_DIR:=${XDG_CACHE_HOME:-$HOME/.cache}/zsh}
[[ -d $ZSH_CACHE_DIR/init ]] || command mkdir -p $ZSH_CACHE_DIR/init
zmodload -F zsh/stat b:zstat

# cached-eval <name> <command...>
cached-eval() {
  emulate -L zsh
  local name=$1; shift
  local cache=$ZSH_CACHE_DIR/init/$name.zsh
  local bin=${commands[$1]}

  # Tool not installed: nothing to do.
  [[ -n $bin ]] || return 1

  # First line records the binary's mtime and the exact command. The mtime is
  # compared for equality, not age: a package's files carry their build date,
  # which can be older than the cache. Read with the builtin redirect rather
  # than $(head -1) -- a fork here would undo the point.
  local -a mtime
  zstat -A mtime +mtime -- $bin 2>/dev/null
  local stamp="# cached-eval: $mtime $*" first=''
  [[ -s $cache ]] && read -r first < $cache

  if [[ $first != $stamp ]]; then
    local tmp=$cache.$$
    if { print -r -- $stamp; "$@" } >| $tmp 2>/dev/null && [[ -s $tmp ]]; then
      command mv -f $tmp $cache
      zcompile -R -- $cache 2>/dev/null
    else
      # Generation failed. Fall back to evaluating live so the shell still
      # works, and leave any previous cache untouched.
      command rm -f $tmp
      eval "$("$@" 2>/dev/null)"
      return
    fi
  fi

  source $cache
}

# Drop every cached init file; they regenerate on the next shell.
zsh-cache-clear() {
  command rm -rf $ZSH_CACHE_DIR/init
  command mkdir -p $ZSH_CACHE_DIR/init
  print -P "%F{green}✅ Cleared init cache -- open a new shell to regenerate%f"
}
