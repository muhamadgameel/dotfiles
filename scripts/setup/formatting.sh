#!/usr/bin/env bash

# Show help message
show_help() {
  cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Usage: $0 [OPTIONS]

Options:
  -h, --help              Show this help message
  -a, --auto-confirm      Auto-confirm all prompts
  -d, --dry-run           Show what would be done without making changes

Examples:
  $0                      # Interactive setup
  $0 -a                   # Auto-confirm all prompts
  $0 --dry-run            # Preview changes without applying
EOF
}

# Logging function
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local log_entry="$timestamp [$level] $message"

  echo -e "$log_entry" >> "$LOG_FILE"
}

# Print function with levels
print_message() {
  local level="$1"
  local color="$2"
  local message="$3"
  local timestamp=$(date '+%H:%M:%S')

  case "$level" in
    "INFO")
      echo -e "${color}[$timestamp] ℹ️ $message${NC}"
      ;;
    "SUCCESS")
      echo -e "${color}[$timestamp] ✅ $message${NC}"
      ;;
    "WARNING")
      echo -e "${color}[$timestamp] ⚠️ $message${NC}"
      ;;
    "ERROR")
      echo -e "${color}[$timestamp] ❌ $message${NC}"
      ;;
    "PROGRESS")
      echo -e "${color}[$timestamp] 🔄 $message${NC}"
      ;;
    *)
      echo -e "${color}[$timestamp] $message${NC}"
      ;;
  esac

  log "$level" "$message"
}

# Progress indicator
show_progress() {
  local current="$1"
  local total="$2"
  local message="$3"

  printf "${CYAN}[$current/$total] $message... ${NC}\n"
}

# Show Header message
show_header() {
  print_message "INFO" "$CYAN" "============================================="
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  print_message "INFO" "$BLUE" "🚀 Starting $SCRIPT_NAME v$SCRIPT_VERSION - $timestamp"
  print_message "INFO" "$CYAN" "============================================="
}

# Show current configuration
show_configuration() {
  print_message "INFO" "$BLUE" "📋 Configuration:"
  print_message "INFO" "$CYAN" "  Dry run: ${DRY_RUN:-false}"
  print_message "INFO" "$CYAN" "  Auto-confirm: ${AUTO_CONFIRM:-false}"
  print_message "INFO" "$CYAN" "  Configs to apply: ${DOTFILES_CONFIGS[*]}"
}

# Show summary
show_summary() {
  local end_time=$(date +%s)
  local duration=$((end_time - SCRIPT_START_TIME))

  echo
  print_message "INFO" "$CYAN" "============================================="
  print_message "INFO" "$BLUE" "📊 Setup Summary:"
  print_message "INFO" "$BLUE" "Duration: ${duration}s"
  print_message "INFO" "$BLUE" "Log file: $LOG_FILE"
  print_message "INFO" "$CYAN" "============================================="
}
