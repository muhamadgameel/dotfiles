# Inspired by Zap: https://github.com/zap-zsh/zap

: "${XDG_DATA_HOME:=$HOME/.local/share}"
ZPM_DIR="$XDG_DATA_HOME/zpm"
ZPM_PLUGIN_DIR="$ZPM_DIR/plugins"
ZPM_INSTALLED_PLUGINS=""

Plug() {
  _try_source() {
    plugin_dir="$1"
    plugin_name="$2"
    for ext in plugin. ''; do
      for shell in zsh sh; do
        for theme in -theme ''; do
          initfile="$plugin_dir/$plugin_name.$ext$shell$theme"
          if [ -f "$initfile" ]; then
            source "$initfile"
            return 0
          fi
        done
      done
    done
    return 1
  }

  plugin="$1"
  plugin_name=$(basename "$plugin")
  plugin_dir="$ZPM_PLUGIN_DIR/$plugin_name"

  if [ ! -d "$plugin_dir" ]; then
    printf "🔌 Zpm is installing %s...\n" "$plugin_name"
    if git clone --depth 1 "https://github.com/${plugin}.git" "$plugin_dir" >/dev/null 2>&1; then
      printf "\033[1A\033[K⚡ Zpm installed %s\n" "$plugin_name"
    else
      printf "\033[1A\033[K❌ Failed to clone %s\n" "$plugin_name"
      return 12
    fi
  fi

  if _try_source "$plugin_dir" "$plugin_name"; then
    case ":$ZPM_INSTALLED_PLUGINS:" in
      *":$plugin_name:"*) ;;
      *)
        if [ -z "$ZPM_INSTALLED_PLUGINS" ]; then
          ZPM_INSTALLED_PLUGINS="$plugin_name"
        else
          ZPM_INSTALLED_PLUGINS="$ZPM_INSTALLED_PLUGINS:$plugin_name"
        fi
        ;;
    esac
    return 0
  else
    printf "❌ %s not activated\n" "$plugin_name"
    return 1
  fi
}

_pull() {
  printf "🔌 updating %s...\n" "$(basename "$1")"
  if git -C "$1" pull >/dev/null 2>&1; then
    printf "\033[1A\033[K⚡ %s updated!\n" "$(basename "$1")"
    return 0
  else
    printf "\033[1A\033[K❌ Failed to pull\n"
    return 14
  fi
}

_zpm_clean() {
  printf "⚡ Zpm - Clean\n\n"
  unused_found=0
  for plugin in "$ZPM_PLUGIN_DIR"/*; do
    plugin_name=$(basename "$plugin")
    if ! echo ":$ZPM_INSTALLED_PLUGINS:" | grep -q ":$plugin_name:"; then
      unused_found=1
      printf "❔ Remove: %s? (y/N)\n" "$plugin_name"
      read -r answer
      case "$answer" in
        [Yy]*)
          rm -rf "$plugin"
          printf "\033[1A\033[K✅ Removed %s\n" "$plugin_name"
          ;;
        *)
          printf "\033[1A\033[K❕ skipped %s\n" "$plugin_name"
          ;;
      esac
    fi
  done
  if [ "$unused_found" -eq 0 ]; then
    printf "✅ Nothing to remove\n"
  fi
}

_zpm_update() {
  printf "\nUpdating All Plugins\n\n"
  echo "$ZPM_INSTALLED_PLUGINS" | tr ':' '\n' | while read -r plug; do
    if [ -n "$plug" ]; then
      _pull "$ZPM_PLUGIN_DIR/$plug"
    fi
  done
}

_zpm_list() {
  printf "⚡ Zpm - List\n\n"
  i=1
  echo "$ZPM_INSTALLED_PLUGINS" | tr ':' '\n' | while read -r plugin; do
    if [ -n "$plugin" ]; then
      printf "%d %s 🔌\n" "$i" "$plugin"
      i=$((i + 1))
    fi
  done
}

_zpm_help() {
  cat <<EOF
⚡ Zpm - Help

Usage: zpm <command> [options]

COMMANDS:
    clean          Remove unused plugins
    help           Show this help message
    list           List plugins
    update         Update plugins
EOF
}

zpm() {
  case "$1" in
    clean) _zpm_clean ;;
    help) _zpm_help ;;
    list) _zpm_list ;;
    update) _zpm_update ;;
    *)
      _zpm_help
      return 1
      ;;
  esac
}
