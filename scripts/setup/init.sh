#!/usr/bin/env bash

# Detect OS
OS="$(uname -s)"

# Load script utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/formatting.sh"

# Parse command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        SUPPRESS_SUMMARY=true
        show_help
        exit 0
        ;;
      -a|--auto-confirm)
        AUTO_CONFIRM=true
        shift
        ;;
      -d|--dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        SUPPRESS_SUMMARY=true
        print_message "ERROR" "$RED" "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

main() {
  # Initialize script
  init_script

  # Parse command line arguments
  parse_arguments "$@"

  case "$OS" in
    Darwin)
      print_message "SUCCESS" "$GREEN" "🍎 Detected macOS - Running macOS setup..."
      run_macos_setup "$@"
      ;;
    Linux)
      print_message "ERROR" "$RED" "🐧 Linux setup not yet implemented" >&2
      exit 1
      ;;
    *)
      print_message "ERROR" "$RED" "Unsupported OS: $OS" >&2
      exit 1
      ;;
  esac
}

# Execute
main "$@"
