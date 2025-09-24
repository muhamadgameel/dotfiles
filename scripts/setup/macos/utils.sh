#!/usr/bin/env bash

# Homebrew management functions
install_homebrew() {
  print_message "PROGRESS" "$YELLOW" "Installing Homebrew..."

  if [[ "$DRY_RUN" == "true" ]]; then
    print_message "INFO" "$CYAN" "DRY RUN: Would install Homebrew"
    return 0
  fi

  if /bin/bash -c "$(curl -fsSL $HOMEBREW_INSTALL_URL)"; then
    print_message "SUCCESS" "$GREEN" "Homebrew installed successfully"

    # Add Homebrew to PATH for the current session
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    print_message "ERROR" "$RED" "Failed to install Homebrew"
    return 1
  fi
}

update_homebrew() {
  print_message "PROGRESS" "$YELLOW" "Updating Homebrew..."

  if [[ "$DRY_RUN" == "true" ]]; then
    print_message "INFO" "$CYAN" "DRY RUN: Would update Homebrew"
    return 0
  fi

  if brew update; then
    print_message "SUCCESS" "$GREEN" "Homebrew updated successfully"
  else
    print_message "ERROR" "$RED" "Failed to update Homebrew"
    return 1
  fi
}

check_homebrew() {
  if ! command_exists brew; then
    print_message "WARNING" "$YELLOW" "Homebrew not found"
    if confirm_step "install Homebrew" "y"; then
      install_homebrew
    else
      print_message "WARNING" "$YELLOW" "Skipping Homebrew installation"
      return 1
    fi
  else
    print_message "SUCCESS" "$GREEN" "Homebrew is already installed"
      if confirm_step "update Homebrew" "y"; then
        update_homebrew
      else
        print_message "WARNING" "$YELLOW" "Skipping Homebrew update"
      fi
  fi
}

# Package management functions
install_packages() {
  if [[ "$DRY_RUN" == "true" ]]; then
    print_message "INFO" "$CYAN" "DRY RUN: Would install packages from $BREWFILE_PATH"
    return 0
  fi

  if confirm_step "Install packages" "y"; then
    print_message "PROGRESS" "$YELLOW" "Installing packages from Brewfile..."
    if [[ ! -f "$BREWFILE_PATH" ]]; then
      print_message "ERROR" "$RED" "Brewfile not found at $BREWFILE_PATH"
      return 1
    fi

    cd "$MACOS_DIR" || {
      print_message "ERROR" "$RED" "Could not change to macos directory"
      return 1
    }

    if brew bundle -v 2>> "$LOG_FILE"; then
      print_message "SUCCESS" "$GREEN" "Packages installed successfully"
    else
      print_message "ERROR" "$RED" "Brew bundle failed. Check $LOG_FILE for details"
      return 1
    fi

    cd "$ROOT_DIR" || {
      print_message "ERROR" "$RED" "Could not return to root directory"
      return 1
    }
  else
    print_message "WARNING" "$YELLOW" "Skipping package installation"
  fi
}
}
