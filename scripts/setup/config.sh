#!/usr/bin/env bash

# Script settings
readonly SCRIPT_NAME="System Setup"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_AUTHOR="mgameel"

# Directories
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Logging
readonly LOG_DIR="$ROOT_DIR/logs" # TODO: find another location for the logs (preferably in cache)
readonly LOG_FILE="$LOG_DIR/setup_$(date +%Y%m%d_%H%M%S).log"
readonly MAX_LOG_FILES=10

# Configuration arrays
readonly DOTFILES_CONFIGS=("zsh" "nvim" "starship" "alacritty" "gitconfig")

# Color codes
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# Settings
AUTO_CONFIRM=false
DRY_RUN=false
