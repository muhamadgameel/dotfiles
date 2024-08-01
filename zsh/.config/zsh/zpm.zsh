# Inspired by Zap: https://github.com/zap-zsh/zap
emulate -L zsh
setopt extended_glob nomatch nullglob

# Use parameter expansion with default for XDG_DATA_HOME
: ${XDG_DATA_HOME:=$HOME/.local/share}
: ${ZPM_DIR:=$XDG_DATA_HOME/zpm}
: ${ZPM_PLUGIN_DIR:=$ZPM_DIR/plugins}

typeset -gA ZPM_INSTALLED_PLUGINS

Plug() {
  local plugin="$1"
  local plugin_name=${plugin:t}
  local plugin_dir="$ZPM_PLUGIN_DIR/$plugin_name"

  if [[ ! -d "$plugin_dir" ]]; then
    print -P "%F{yellow}🔌 Zpm is installing $plugin_name...%f"
    if git clone --depth 1 "https://github.com/${plugin}.git" "$plugin_dir" &>/dev/null; then
      print -P "\e[1A\e[K%F{green}⚡ Zpm installed $plugin_name%f"
    else
      print -P "\e[1A\e[K%F{red}❌ Failed to clone $plugin_name%f"
      return 1
    fi
  fi

  local initfile=(${plugin_dir}/${plugin_name}.(plugin.|)(zsh|sh)(-theme|)(N))
  if (( $#initfile )); then
    source $initfile[1]
    ZPM_INSTALLED_PLUGINS[$plugin_name]=$plugin_dir
  else
    print -P "%F{red}❌ $plugin_name not activated%f"
    return 1
  fi
}

_zpm_pull() {
  local dir="$1"
  local name=${dir:t}
  print -P "%F{yellow}🔌 Updating $name...%f"
  if git -C "$dir" pull &>/dev/null; then
    print -P "\e[1A\e[K%F{green}⚡ $name updated!%f"
  else
    print -P "\e[1A\e[K%F{red}❌ Failed to update $name%f"
    return 1
  fi
}

_zpm_clean() {
  print -P "%F{blue}⚡ Zpm - Clean%f\n"
  local unused_found=0
  for plugin in $ZPM_PLUGIN_DIR/*(/); do
    local plugin_name=${plugin:t}
    if (( ! ${+ZPM_INSTALLED_PLUGINS[$plugin_name]} )); then
      unused_found=1
      print -P "%F{yellow}❔ Remove: $plugin_name? (y/N)%f"
      read -q "answer?"; echo
      if [[ $answer == [Yy] ]]; then
        rm -rf "$plugin"
        print -P "%F{green}✅ Removed $plugin_name%f"
      else
        print -P "%F{cyan}❕ Skipped $plugin_name%f"
      fi
    fi
  done
  (( unused_found )) || print -P "%F{green}✅ Nothing to remove%f"
}

_zpm_update() {
  print -P "\n%F{blue}Updating All Plugins%f\n"
  for plugin plugin_dir in ${(kv)ZPM_INSTALLED_PLUGINS}; do
    _zpm_pull "$plugin_dir"
  done
}

_zpm_list() {
  print -P "%F{blue}⚡ Zpm - List%f\n"
  integer i=1
  for plugin plugin_dir in ${(kv)ZPM_INSTALLED_PLUGINS}; do
    print -P "%F{yellow}$i%f %F{green}$plugin%f 🔌 ($plugin_dir)"
    ((i++))
  done
}

_zpm_help() {
  print -P "%F{blue}⚡ Zpm - Help%f
Usage: zpm <command>

COMMANDS:
    %F{green}clean%f          Remove unused plugins
    %F{green}help%f           Show this help message
    %F{green}list%f           List installed plugins
    %F{green}update%f         Update all plugins"
}

zpm() {
  # Initialize plugin directory
  [[ -d $ZPM_PLUGIN_DIR ]] || mkdir -p $ZPM_PLUGIN_DIR

  local cmd="${1:-help}"
  case "$cmd" in
    clean) _zpm_clean ;;
    list) _zpm_list ;;
    update) _zpm_update ;;
    help|*) _zpm_help ;;
  esac
}
