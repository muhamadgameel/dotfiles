#!/usr/bin/env bash

# Directories
readonly MACOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration arrays
readonly REQUIRED_COMMANDS=("curl" "osascript")

# Homebrew settings
readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly BREWFILE_PATH="$MACOS_DIR/Brewfile"
