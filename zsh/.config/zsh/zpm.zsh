# Inspired by Zap: https://github.com/zap-zsh/zap

export ZPM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zpm"
export ZPM_PLUGIN_DIR="$ZPM_DIR/plugins"
export -a ZPM_INSTALLED_PLUGINS=()

function Plug() {

  function _try_source() {
    local -a initfiles=($plugin_dir/${plugin_name}.{plugin.,}{z,}sh{-theme,}(N))

    (( $#initfiles )) && source $initfiles[1]
  }
  
  local plugin="$1"
  local plugin_name="${plugin:t}"
  local plugin_dir="$ZPM_PLUGIN_DIR/$plugin_name"

  if [ ! -d "$plugin_dir" ]; then
    echo "🔌 Zpm is installing $plugin_name..."
    git clone --depth 1 "https://github.com/${plugin}.git" "$plugin_dir" > /dev/null 2>&1 || { echo -e "\e[1A\e[K❌ Failed to clone $plugin_name"; return 12 }
    echo -e "\e[1A\e[K⚡ Zpm installed $plugin_name"
  fi

  _try_source && { ZPM_INSTALLED_PLUGINS+="$plugin_name" && return 0 } || echo "❌ $plugin_name not activated" && return 1
}

function _pull() {
  echo "🔌 updating ${1:t}..."
  git -C $1 pull > /dev/null 2>&1 && { echo -e "\e[1A\e[K⚡ ${1:t} updated!"; return 0 } || { echo -e "\e[1A\e[K❌ Failed to pull"; return 14 }
}

function _zpm_clean() {
  typeset -a unused_plugins=()
  echo "⚡ Zpm - Clean\n"
  for plugin in "$ZPM_PLUGIN_DIR"/*; do
    [[ "$ZPM_INSTALLED_PLUGINS[(Ie)${plugin:t}]" -eq 0 ]] && unused_plugins+=("${plugin:t}")
  done
  [[ ${#unused_plugins[@]} -eq 0 ]] && { echo "✅ Nothing to remove"; return 15 }
  for plug in ${unused_plugins[@]}; do
    echo "❔ Remove: $plug? (y/N)"
    read -qs answer
    [[ "$answer" == "y" ]] && { rm -rf "$ZPM_PLUGIN_DIR/$plug" && echo -e "\e[1A\e[K✅ Removed $plug" } || echo -e "\e[1A\e[K❕ skipped $plug"
  done
}

function _zpm_update() {
  local _plugin _plug _status

  echo "\nUpdating All Plugins\n"
  for _plug in ${ZPM_INSTALLED_PLUGINS[@]}; do
      _pull "$ZPM_PLUGIN_DIR/$_plug"
  done
}

function _zpm_list() {
  local _plugin
  echo "⚡ Zpm - List\n"
  for _plugin in ${ZPM_INSTALLED_PLUGINS[@]}; do
    printf "$ZPM_INSTALLED_PLUGINS[(Ie)$_plugin] $_plugin 🔌\n"
  done
}

function _zpm_help() {
  echo "⚡ Zpm - Help

Usage: zpm <command> [options]

COMMANDS:
    clean          Remove unused plugins
    help           Show this help message
    list           List plugins
    update         Update plugins
    version        Show version information"
}

function zpm() {
  typeset -A subcmds=(
    clean "_zpm_clean"
    help "_zpm_help"
    list "_zpm_list"
    update "_zpm_update"
  )
  emulate -L zsh
  [[ -z "$subcmds[$1]" ]] && { _zpm_help; return 1 } || ${subcmds[$1]} $2
}

