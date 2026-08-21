# Inspired by Zap: https://github.com/zap-zsh/zap
#
# NOTE: deliberately no `emulate`/`setopt` at file scope. This file is sourced
# from init.zsh outside any function, so `emulate -L zsh` would not restore on
# return -- it would reset the options settings.zsh had just set, and leak
# nullglob shell-wide. The globs below need neither: parenthesised alternation
# is core zsh globbing, and `(N)` is a per-glob nullglob qualifier.
#
# Usage:
#   Plug "owner/repo"                 # GitHub shorthand
#   Plug "owner/repo" "v1.2.0"        # pinned to a tag, branch or commit
#   Plug "https://example.com/x.git"  # any git URL
#   Plug "~/code/my-plugin"           # local directory, never cloned or updated

# Use parameter expansion with default for XDG_DATA_HOME
: ${XDG_DATA_HOME:=$HOME/.local/share}
: ${ZPM_DIR:=$XDG_DATA_HOME/zpm}
: ${ZPM_PLUGIN_DIR:=$ZPM_DIR/plugins}

# Plugins that loaded successfully in this shell: key -> directory
typeset -gA ZPM_INSTALLED_PLUGINS
# Every plugin declared via Plug, whether or not it loaded: key -> directory.
# `zpm clean` compares against this rather than against the loaded set, so a
# plugin that failed to source is not mistaken for an orphan and deleted.
typeset -gA ZPM_DECLARED_PLUGINS
# Plugins pinned to a git ref: key -> ref. These are skipped by `zpm update`.
typeset -gA ZPM_PINNED_PLUGINS
# Plugins loaded from a local path: key -> path. Never cloned, updated or cleaned.
typeset -gA ZPM_LOCAL_PLUGINS

# ===== Output helpers

# Failures go to stderr so they survive `zpm list > file` and stay visible when
# zpm's stdout is being captured.
_zpm_error() { print -u2 -P "$@" }

# Replace the previous line, but only on a terminal: the cursor-up escape would
# otherwise be written into a redirect, and if the previous message wrapped onto
# several lines it would erase the wrong one.
_zpm_replace() {
  [[ -t 1 ]] && print -nP '\e[1A\e[K'
  print -P "$@"
}

# ===== Spec parsing
#
# A plugin is keyed by its full slug (owner---repo), not just the repo name.
# Keying on the basename alone makes `a/zsh-async` and `b/zsh-async` collide:
# they share a directory and whichever loads first silently wins.

# These set $REPLY rather than printing. Capturing output with $(...) forks a
# subshell -- at three helper calls per plugin that measurably doubled Plug's
# own startup cost, which is more than byte-compiling saves.
_zpm_is_local() { [[ $1 == (/*|~*|./*|../*) ]] }

_zpm_key() {
  case $1 in
    (*://*|git@*) REPLY=${${1:t}%.git} ;;
    (/*|~*|./*|../*) REPLY=${1:t} ;;
    (*) REPLY=${1//\//---} ;;
  esac
}

# The repo's own basename, used to find its init file -- the file inside is
# named after the repo (zsh-completions.plugin.zsh), not after our slug key.
_zpm_repo() { REPLY=${${1%.git}:t} }

# Short, human-facing name: the repo half of the slug. Falls back to the full
# key when two declared plugins share a repo name -- otherwise the display
# would throw away exactly the disambiguation the slug key exists to provide.
_zpm_display() {
  local key=$1 short=${1##*---} other
  for other in ${(k)ZPM_DECLARED_PLUGINS}; do
    [[ $other == $key ]] && continue
    if [[ ${other##*---} == $short ]]; then
      REPLY=$key
      return
    fi
  done
  REPLY=$short
}

_zpm_url() {
  case $1 in
    (*://*|git@*) REPLY=$1 ;;
    (*) REPLY="https://github.com/${1}.git" ;;
  esac
}

# ===== Loading

# Locate a plugin's entry point, most specific first.
_zpm_initfile() {
  local dir=$1 repo=$2
  local -a candidates=(
    $dir/$repo.(plugin.|)(zsh|sh)(-theme|)(N)
    $dir/*.plugin.zsh(N)
    $dir/init.zsh(N)
  )
  REPLY=''
  (( $#candidates )) && REPLY=$candidates[1]
  [[ -n $REPLY ]]
}

# Byte-compile one file. zsh prefers a .zwc automatically when it is newer than
# its source.
_zpm_zcompile_file() {
  local f=$1
  [[ -s $f && -w ${f:h} ]] || return 1
  [[ -s $f.zwc && ! $f -nt $f.zwc ]] && return 0
  zcompile -R -- $f 2>/dev/null
}

# Compile a plugin's entry point *and* its top-level payload.
#
# Compiling only the entry point is close to useless: most plugins ship a
# <name>.plugin.zsh stub of a few dozen bytes that just sources the real file.
# The parse cost lives in that payload (20-30KB each here), and compiling it is
# worth ~20% of total plugin source time. Restricted to the plugin root on
# purpose -- deeper trees are test fixtures and vendored data, not startup code.
_zpm_zcompile() {
  local dir=$1 initfile=$2 f
  _zpm_zcompile_file $initfile
  for f in $dir/*.zsh(N.); do
    [[ $f == $initfile ]] && continue
    _zpm_zcompile_file $f
  done
}

# Completion-only repos ship no init file, just _foo functions. Add the
# directory holding them to fpath instead of reporting the plugin as broken.
_zpm_add_fpath() {
  local dir=$1 d
  local -a comps
  for d in $dir/src(N/) $dir/functions(N/) $dir(N/); do
    comps=($d/_*(N.))
    if (( $#comps )); then
      fpath+=$d
      return 0
    fi
  done
  return 1
}

Plug() {
  local spec=$1 ref=$2
  if [[ -z $spec ]]; then
    _zpm_error "%F{red}❌ Plug: missing plugin argument%f"
    return 1
  fi

  local key repo
  _zpm_key $spec;  key=$REPLY
  _zpm_repo $spec; repo=$REPLY
  local dir

  if _zpm_is_local $spec; then
    dir=${~spec}
    if [[ ! -d $dir ]]; then
      _zpm_error "%F{red}❌ $key: no such directory: $dir%f"
      return 1
    fi
    ZPM_LOCAL_PLUGINS[$key]=$dir
  else
    dir=$ZPM_PLUGIN_DIR/$key

    if [[ ! -d $dir ]]; then
      print -P "%F{yellow}🔌 Zpm is installing $key...%f"
      _zpm_url $spec
      local url=$REPLY
      if git clone --depth 1 $url "$dir" &>/dev/null; then
        _zpm_replace "%F{green}⚡ Zpm installed $key%f"
      else
        _zpm_replace "%F{red}❌ Failed to clone $key%f"
        _zpm_error "%F{red}   $url%f"
        return 1
      fi
    fi

    # Pinning: fetch the exact ref shallowly and detach onto it.
    #
    # Which ref is checked out is recorded in a marker file rather than derived
    # from git. A shallow `fetch origin <tag>` never creates a local tag ref, so
    # `git describe` cannot name the commit -- using that as the idempotence
    # check would miss every time and re-hit the network on every single shell
    # startup.
    if [[ -n $ref ]]; then
      ZPM_PINNED_PLUGINS[$key]=$ref
      local marker=$dir/.zpm-ref
      if [[ ! -r $marker || $(<$marker) != $ref ]]; then
        if git -C "$dir" fetch --depth 1 origin "$ref" &>/dev/null &&
           git -C "$dir" checkout --detach FETCH_HEAD &>/dev/null; then
          print -r -- $ref >$marker
          print -P "%F{green}📌 $key pinned to $ref%f"
        else
          _zpm_error "%F{red}❌ $key: cannot check out ref $ref%f"
        fi
      fi
    elif [[ -r $dir/.zpm-ref ]]; then
      # Previously pinned, no longer: leave the detached HEAD behind and let the
      # next `zpm update` fast-forward it back onto upstream.
      command rm -f $dir/.zpm-ref
      print -P "%F{cyan}↻ $key unpinned%f"
    fi
  fi

  ZPM_DECLARED_PLUGINS[$key]=$dir

  local initfile=''
  _zpm_initfile $dir $repo && initfile=$REPLY
  if [[ -n $initfile ]]; then
    _zpm_zcompile $dir $initfile
    if source $initfile; then
      ZPM_INSTALLED_PLUGINS[$key]=$dir
      return 0
    fi
    # A plugin that errors while sourcing must not be recorded as installed --
    # otherwise `zpm clean` treats it as an orphan and offers to delete it.
    _zpm_error "%F{red}❌ $key failed while sourcing ${initfile:t}%f"
    return 1
  fi

  if _zpm_add_fpath $dir; then
    ZPM_INSTALLED_PLUGINS[$key]=$dir
    return 0
  fi

  _zpm_error "%F{red}❌ $key not activated (no init file or completions found)%f"
  return 1
}

# ===== Commands

# Update one plugin. Prints a single status line; safe to run in background.
#
# `git pull` is wrong for these shallow clones: with a diverged local checkout
# it reports "up to date" and exits 0 while the plugin silently stops tracking
# upstream, and it cannot recover from a force-push. fetch+reset is idempotent.
_zpm_pull() {
  local key=$1 dir=$2
  local before after

  before=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
  if ! git -C "$dir" fetch --depth 1 origin HEAD &>/dev/null; then
    print -P "%F{red}❌ $key: fetch failed%f"
    return 1
  fi
  if ! git -C "$dir" reset --hard FETCH_HEAD &>/dev/null; then
    print -P "%F{red}❌ $key: reset failed%f"
    return 1
  fi
  after=$(git -C "$dir" rev-parse HEAD 2>/dev/null)

  if [[ $before == $after ]]; then
    print -P "%F{blue}•%f $key %F{242}already current%f"
  else
    print -P "%F{green}⚡%f $key %F{242}${before[1,7]} -> ${after[1,7]}%f"
    # The old .zwc now shadows newer source, so drop it and rebuild on next load.
    command rm -f $dir/**/*.zwc(N)
  fi
}

_zpm_update() {
  print -P "%F{blue}⚡ Zpm - Update%f\n"

  local -a targets
  local key
  for key in ${(ko)ZPM_DECLARED_PLUGINS}; do
    (( ${+ZPM_LOCAL_PLUGINS[$key]} )) && continue
    if (( ${+ZPM_PINNED_PLUGINS[$key]} )); then
      print -P "%F{242}📌 $key pinned to ${ZPM_PINNED_PLUGINS[$key]}, skipping%f"
      continue
    fi
    targets+=$key
  done

  if (( ! $#targets )); then
    print -P "%F{green}✅ Nothing to update%f"
    return 0
  fi

  # Fetch in parallel -- these are network-bound, so serialising them makes the
  # whole command as slow as the sum of the round-trips instead of the slowest.
  local tmp=$(command mktemp -d "${TMPDIR:-/tmp}/zpm-update-XXXXXX") || return 1
  for key in $targets; do
    _zpm_pull $key ${ZPM_DECLARED_PLUGINS[$key]} >$tmp/$key 2>&1 &
  done
  wait

  # Replay in declaration order so output is stable run to run.
  for key in $targets; do
    [[ -s $tmp/$key ]] && command cat $tmp/$key
  done
  command rm -rf $tmp
}

_zpm_clean() {
  print -P "%F{blue}⚡ Zpm - Clean%f\n"
  local unused_found=0 plugin key answer
  for plugin in $ZPM_PLUGIN_DIR/*(N/); do
    key=${plugin:t}
    # Compare against declared, not loaded: a plugin that failed to source is
    # still wanted.
    (( ${+ZPM_DECLARED_PLUGINS[$key]} )) && continue
    unused_found=1
    print -P "%F{yellow}❔ Remove: $key? (y/N)%f"
    read -q "answer?"; echo
    if [[ $answer == [Yy] ]]; then
      command rm -rf "$plugin"
      print -P "%F{green}✅ Removed $key%f"
    else
      print -P "%F{cyan}❕ Skipped $key%f"
    fi
  done
  (( unused_found )) || print -P "%F{green}✅ Nothing to remove%f"
}

_zpm_list() {
  print -P "%F{blue}⚡ Zpm - List%f\n"
  local key
  integer i=1
  for key in ${(ko)ZPM_DECLARED_PLUGINS}; do
    local tag=''
    (( ${+ZPM_LOCAL_PLUGINS[$key]} ))  && tag+=" %F{cyan}[local]%f"
    (( ${+ZPM_PINNED_PLUGINS[$key]} )) && tag+=" %F{242}📌${ZPM_PINNED_PLUGINS[$key]}%f"
    (( ${+ZPM_INSTALLED_PLUGINS[$key]} )) || tag+=" %F{red}[not loaded]%f"
    _zpm_display $key
    print -P "%F{yellow}$i%f %F{green}$REPLY%f 🔌${tag} %F{242}(${ZPM_DECLARED_PLUGINS[$key]})%f"
    (( i++ ))
  done
  (( i > 1 )) || print -P "%F{242}no plugins declared%f"
}

# Report the states that are otherwise invisible: declared plugins that never
# loaded, directories nothing declares, uncompiled or locally-modified repos.
_zpm_doctor() {
  print -P "%F{blue}⚡ Zpm - Doctor%f\n"
  integer problems=0
  local key dir

  for key in ${(ko)ZPM_DECLARED_PLUGINS}; do
    (( ${+ZPM_INSTALLED_PLUGINS[$key]} )) && continue
    _zpm_display $key
    print -P "%F{red}✖%f $REPLY declared but not loaded"
    (( problems++ ))
  done

  for dir in $ZPM_PLUGIN_DIR/*(N/); do
    (( ${+ZPM_DECLARED_PLUGINS[${dir:t}]} )) && continue
    print -P "%F{yellow}▲%f ${${dir:t}##*---} on disk but not declared %F{242}(zpm clean)%f"
    (( problems++ ))
  done

  local name
  for key in ${(ko)ZPM_INSTALLED_PLUGINS}; do
    dir=${ZPM_INSTALLED_PLUGINS[$key]}
    _zpm_display $key; name=$REPLY
    # Flag any top-level .zsh that has no (or a stale) .zwc beside it.
    local -a uncompiled=($dir/*.zsh(N.e:'[[ ! -s $REPLY.zwc || $REPLY -nt $REPLY.zwc ]]':))
    if (( $#uncompiled )); then
      print -P "%F{yellow}▲%f $name has ${#uncompiled} uncompiled file(s) %F{242}(zpm compile)%f"
      (( problems++ ))
    fi
    # -uno: ignore untracked files. zpm's own .zpm-ref marker lives here, and
    # modifications to tracked files are the signal that actually matters.
    if [[ -d $dir/.git ]] && [[ -n $(git -C $dir status --porcelain -uno 2>/dev/null) ]]; then
      print -P "%F{yellow}▲%f $name has local modifications"
      (( problems++ ))
    fi
  done

  (( problems )) || print -P "%F{green}✅ Everything looks fine%f"
}

_zpm_compile() {
  print -P "%F{blue}⚡ Zpm - Compile%f\n"
  local key dir initfile
  local -a zwcs names
  integer n=0
  # One line per plugin. A plugin legitimately yields several .zwc files -- the
  # <name>.plugin.zsh entry stub and the payload it sources are separate files,
  # so listing each on its own row reads like duplicated output.
  for key in ${(ko)ZPM_INSTALLED_PLUGINS}; do
    dir=${ZPM_INSTALLED_PLUGINS[$key]}
    _zpm_repo $key
    _zpm_initfile $dir $REPLY || continue
    initfile=$REPLY
    command rm -f $dir/*.zwc(N)
    _zpm_zcompile $dir $initfile
    zwcs=($dir/*.zwc(N.))
    (( $#zwcs )) || continue
    _zpm_display $key
    # Apply the modifiers into a real array first. Chaining them inside a nested
    # expansion -- ${(j:, :)${zwcs:t:r}} -- collapses the array to one element.
    names=(${zwcs:t:r})
    print -P "%F{green}⚡%f $REPLY %F{242}(${(j:, :)names})%f"
    (( n += $#zwcs ))
  done
  print -P "\n%F{green}✅ Compiled $n file(s) across ${#ZPM_INSTALLED_PLUGINS} plugin(s)%f"
}

_zpm_help() {
  print -P "%F{blue}⚡ Zpm - Help%f
Usage: zpm <command>

COMMANDS:
    %F{green}clean%f          Remove plugins that are no longer declared
    %F{green}compile%f        Rebuild the .zwc byte-code cache
    %F{green}doctor%f         Report problems with the current setup
    %F{green}help%f           Show this help message
    %F{green}list%f           List declared plugins
    %F{green}update%f         Update all plugins (parallel; skips pinned)"
}

zpm() {
  # Initialize plugin directory
  [[ -d $ZPM_PLUGIN_DIR ]] || command mkdir -p $ZPM_PLUGIN_DIR

  local cmd="${1:-help}"
  case "$cmd" in
    clean) _zpm_clean ;;
    compile) _zpm_compile ;;
    doctor) _zpm_doctor ;;
    list) _zpm_list ;;
    update) _zpm_update ;;
    help) _zpm_help ;;
    *) _zpm_error "%F{red}❌ unknown command: $cmd%f"; _zpm_help; return 1 ;;
  esac
}
