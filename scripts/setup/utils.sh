#!/usr/bin/env bash

# Global variables
declare SCRIPT_START_TIME

# Initialize script
init_script() {
  SCRIPT_START_TIME=$(date +%s)

  # Create log directory
  mkdir -p "$LOG_DIR"

  # Clean old log files
  cleanup_old_logs

  # Set up error handling
  set -euo pipefail
  trap 'handle_error $? $LINENO' ERR
  trap 'cleanup_on_exit' EXIT
}

# Clean up old log files
cleanup_old_logs() {
  if [[ -d "$LOG_DIR" ]]; then
    local log_count=$(find "$LOG_DIR" -name "setup_*.log" | wc -l)
    if [[ $log_count -gt $MAX_LOG_FILES ]]; then
      find "$LOG_DIR" -name "setup_*.log" -type f -exec stat -f "%m %N" {} \; | \
        sort -n | head -n $((log_count - MAX_LOG_FILES)) | \
        cut -d' ' -f2- | xargs rm -f
    fi
  fi
}

# Error handling
handle_error() {
  local exit_code="$1"
  local line_number="$2"

  print_message "ERROR" "$RED" "Script failed at line $line_number with exit code $exit_code"

  exit "$exit_code"
}

# Cleanup on exit
cleanup_on_exit() {
  local exit_code="$?"

  if [[ "${SUPPRESS_SUMMARY:-false}" != "true" ]]; then
    if [[ $exit_code -eq 0 ]]; then
      print_message "SUCCESS" "$GREEN" "Script completed successfully"
      show_summary
    else
      print_message "ERROR" "$RED" "Script exited with error code $exit_code"
    fi
  fi
}

# Confirmation function
confirm_step() {
  local step_name="$1"
  local default="${2:-n}"
  local prompt

  # Set prompt based on default
  if [[ "$default" == "y" ]]; then
    prompt="Do you want to $step_name? [Y/n]: "
  else
    prompt="Do you want to $step_name? [y/N]: "
  fi

  # Auto-confirm if enabled
  if [[ "${AUTO_CONFIRM:-false}" == "true" ]]; then
    print_message "INFO" "$YELLOW" "Auto-confirming: $step_name"
    return 0
  fi

  while true; do
    read -p "$prompt" -n 1 -r
    echo
    case $REPLY in
      [Yy])
        return 0
        ;;
      [Nn])
        return 1
        ;;
      "")
        # Handle empty input - return default
        if [[ "$default" == "y" ]]; then
          return 0
        else
          return 1
        fi
        ;;
      *)
        print_message "WARNING" "$YELLOW" "Please answer y or n."
        ;;
    esac
  done
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
  print_message "INFO" "$BLUE" "🔍 Checking system requirements..."

  local missing_required=()

  # Check required commands
  for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$cmd"; then
      missing_required+=("$cmd")
    fi
  done

  # Report missing commands
  if [[ ${#missing_required[@]} -gt 0 ]]; then
    print_message "ERROR" "$RED" "Missing required commands: ${missing_required[*]}"
    print_message "ERROR" "$RED" "Please install these commands and run the script again"
    exit 1
  fi

  print_message "SUCCESS" "$GREEN" "System requirements check passed"
}

# # Dotfiles management functions
validate_dotfiles() {
  print_message "INFO" "$BLUE" "Validating dotfiles..."

  for config in "${DOTFILES_CONFIGS[@]}"; do
    local config_path="$ROOT_DIR/$config"
    if [[ ! -d "$config_path" ]]; then
      print_message "WARNING" "$YELLOW" "Config directory not found: $config"
      continue
    fi

    # Check for common issues
    if [[ -f "$config_path/.git" ]]; then
      print_message "WARNING" "$YELLOW" "Config $config appears to be a git submodule"
    fi

    print_message "SUCCESS" "$GREEN" "Config $config validated"
  done
}

apply_dotfiles() {
  print_message "PROGRESS" "$YELLOW" "Applying dotfiles..."

  if [[ "$DRY_RUN" == "true" ]]; then
    print_message "INFO" "$CYAN" "DRY RUN: Would apply dotfiles: ${DOTFILES_CONFIGS[*]}"
    return 0
  fi

  # Validate dotfiles first
  validate_dotfiles

  # Check if stow is available
  if ! command_exists stow; then
    print_message "ERROR" "$RED" "Stow is not installed. Please install it first."
    return 1
  fi

  # Perform dry run first
  print_message "INFO" "$YELLOW" "Performing dry run to show what will be applied..."
  if stow -nv -t ~ -S "${DOTFILES_CONFIGS[@]}" 2>&1 | tee -a "$LOG_FILE"; then
    print_message "SUCCESS" "$GREEN" "Dry run completed successfully"
    echo

    if confirm_step "apply the dotfiles shown above" "y"; then
      print_message "PROGRESS" "$YELLOW" "Applying configurations..."
      if stow -v -t ~ -S "${DOTFILES_CONFIGS[@]}" 2>> "$LOG_FILE"; then
        print_message "SUCCESS" "$GREEN" "Dotfiles applied successfully"
      else
        print_message "ERROR" "$RED" "Stow operation failed. Check $LOG_FILE for details"
        return 1
      fi
    else
      print_message "WARNING" "$YELLOW" "Skipping dotfiles application"
    fi
  else
    print_message "ERROR" "$RED" "Stow dry run failed. Check $LOG_FILE for details"
    return 1
  fi
}

# Run macOS setup
run_macos_setup() {
  show_header
  show_configuration
  source "$SCRIPT_DIR/macos/config.sh"
  source "$SCRIPT_DIR/macos/utils.sh"
  check_requirements

  # Main setup steps
  local steps=()
  local step_count=0

  # Add steps
  steps+=("check_homebrew")
  steps+=("install_packages")
  steps+=("apply_dotfiles")

  step_count=${#steps[@]}

  # Execute steps
  for i in "${!steps[@]}"; do
    local step="${steps[$i]}"
    local step_num=$((i + 1))

    show_progress "$step_num" "$step_count" "Executing $step"
    sleep 2

    if "$step"; then
      print_message "SUCCESS" "$GREEN" "Step $step completed successfully"
    else
      print_message "ERROR" "$RED" "Step $step failed"
      exit 1
    fi
  done
}
