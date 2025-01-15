#!/usr/bin/env bash

# Exit on any error
set -e

# Define color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define configurations array
CONFIGS=("zsh" "nvim" "starship" "kitty" "gitconfig")

# Store root directory
ROOT_DIR=$PWD

# Define log file
LOG_FILE="$ROOT_DIR/setup_$(date +%Y%m%d_%H%M%S).log"

# Helper functions
log() {
  local message="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "$timestamp $message" >> "$LOG_FILE"
}

print_message() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
  log "${message}"
}

install_homebrew() {
  print_message "$YELLOW" "🍺 Installing Homebrew..."
  if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    print_message "$GREEN" "✅ Homebrew installed successfully"
    
    # Add Homebrew to PATH for the current session
    if [[ $(uname -m) == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    print_message "$RED" "❌ Failed to install Homebrew"
    exit 1
  fi
}

check_homebrew() {
  if ! command -v brew &> /dev/null; then
    print_message "$YELLOW" "🔍 Homebrew not found. Installing..."
    install_homebrew
  else
    print_message "$GREEN" "✅ Homebrew is already installed"
    # Update Homebrew
    print_message "$YELLOW" "🔄 Updating Homebrew..."
    if brew update; then
      print_message "$GREEN" "✅ Homebrew updated successfully"
    else
      print_message "$RED" "❌ Failed to update Homebrew"
      exit 1
    fi
  fi
}

# Start setup
print_message "$CYAN" "============================================="
print_message "$BLUE" "🚀 Starting MacOS Setup - $(date '+%Y-%m-%d %H:%M:%S')"
print_message "$CYAN" "============================================="

# Check and install Homebrew
check_homebrew

# Install packages
print_message "$YELLOW" "📦 Installing packages..."
cd "./scripts/macos/" || {
  print_message "$RED" "❌ Error: Could not find macos scripts directory"
  exit 1
}

if brew bundle -v 2>> "$LOG_FILE"; then
  print_message "$GREEN" "✅ Packages installed successfully"
else
  print_message "$RED" "❌ Error: Brew bundle failed. Check $LOG_FILE for details"
  exit 1
fi

# Apply dotfiles
print_message "$YELLOW" "🔧 Applying dotfiles..."
cd "$ROOT_DIR" || {
  print_message "$RED" "❌ Error: Could not return to root directory"
  exit 1
}

print_message "$YELLOW" "🔍 Performing dry run of stow..."
if stow -nv -t ~ -S "${CONFIGS[@]}" 2>> "$LOG_FILE"; then
  # If dry run successful, do the actual stow
  print_message "$YELLOW" "📝 Applying configurations..."
  if stow -v -t ~ -S "${CONFIGS[@]}" 2>> "$LOG_FILE"; then
    print_message "$GREEN" "✅ Dotfiles applied successfully"
  else
    print_message "$RED" "❌ Error: Stow operation failed. Check $LOG_FILE for details"
    exit 1
  fi
else
  print_message "$RED" "❌ Error: Stow dry run failed. Check $LOG_FILE for details"
  exit 1
fi

# TODO Apply Mac settings
# TODO Import GPG keys

# Create summary
echo
print_message "$CYAN" "======================================="
print_message "$BLUE" "📊 Setup Summary:"
print_message "$GREEN" "✅ Packages installed"
print_message "$GREEN" "✅ Dotfiles configured"
print_message "$BLUE" "📝 Log file: $LOG_FILE"
print_message "$CYAN" "======================================="
print_message "$BLUE" "🎉 System setup completed successfully!"
print_message "$CYAN" "======================================="
