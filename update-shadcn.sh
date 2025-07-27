#!/bin/bash
#
# Update shadcn UI components with backup/restore functionality

set -euo pipefail

# Define help function
show_usage() {
  cat <<EOF
Usage: $0 [options] <path_to_ui_directory>
Options:
  -b, --branch <branch>  Specify shadcn branch (latest or canary). Default: latest
  -a, --auto-remove      Automatically remove backup if component count matches
  -h, --help             Show this help message

Default directory: src/components/ui
EOF
  exit 1
}

# Print colored message
print_msg() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${RESET}"
}

# Log error message and exit
log_error() {
  print_msg "$RED" "Error: $1" >&2
  exit 1
}

# Check if command exists
check_command() {
  command -v "$1" >/dev/null 2>&1 || log_error "Required command '$1' not found. Please install it first."
}

# Check for required commands
check_command find
check_command sort
check_command grep

# Default values
SHADCN_BRANCH="latest"
UI_DIR="src/components/ui"
AUTO_REMOVE=false
BACKUP_DIR=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--branch)
      if [[ -z "${2:-}" || "$2" =~ ^- ]]; then
        log_error "Missing value for --branch option"
      fi
      SHADCN_BRANCH="$2"
      if [[ "$SHADCN_BRANCH" != "latest" && "$SHADCN_BRANCH" != "canary" ]]; then
        log_error "Branch must be 'latest' or 'canary'"
      fi
      shift 2
      ;;
    -a|--auto-remove)
      AUTO_REMOVE=true
      shift
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      UI_DIR="$1"
      shift
      ;;
  esac
done

# Validate UI directory exists
if [[ ! -d "$UI_DIR" ]]; then
  log_error "UI directory '$UI_DIR' not found!"
fi

print_msg "$BLUE" "Preparing to update shadcn components in: $UI_DIR"

# Check for existing backups with proper error handling
BACKUP_PATTERN="${UI_DIR}.backup.*"
EXISTING_BACKUPS=()
if [[ -n "$(find . -maxdepth 1 -type d -name "${UI_DIR}.backup.*" 2>/dev/null)" ]]; then
  mapfile -t EXISTING_BACKUPS < <(find . -maxdepth 1 -type d -name "${UI_DIR}.backup.*" | sort)
fi

# Ask user if they want to restore from a backup
if [[ ${#EXISTING_BACKUPS[@]} -gt 0 ]]; then
  print_msg "$GREEN" "Found ${#EXISTING_BACKUPS[@]} existing backups:"

  # Display available backups with indices
  for i in "${!EXISTING_BACKUPS[@]}"; do
    backup_date=$(echo "${EXISTING_BACKUPS[$i]}" | grep -oP "backup.\K[0-9_]+")
    formatted_date=$(echo "$backup_date" | sed -E 's/([0-9]{8})_([0-9]{2})([0-9]{2})([0-9]{2})/\1 \2:\3:\4/')
    echo "[$i] ${EXISTING_BACKUPS[$i]} (${formatted_date})"
  done

  echo "[n] Don't restore, continue with new backup"

  # Ask user to choose
  read -p "Restore from a backup? Enter number or 'n': " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -lt ${#EXISTING_BACKUPS[@]} ]; then
    selected_backup="${EXISTING_BACKUPS[$choice]}"
    print_msg "$YELLOW" "Restoring from: $selected_backup"

    # Backup current directory before restoring
    TEMP_BACKUP="${UI_DIR}.temp.$(date +%Y%m%d_%H%M%S)"
    cp -r "$UI_DIR" "$TEMP_BACKUP"

    # Restore from selected backup
    rm -rf "$UI_DIR"
    cp -r "$selected_backup" "$UI_DIR"

    rm -rf "$selected_backup"
    rm -rf "$TEMP_BACKUP"

    print_msg "$GREEN" "✅ Restored components from backup"
    exit 0
  else
    print_msg "$YELLOW" "Continuing with new backup..."
  fi
fi

BACKUP_DIR="${UI_DIR}.backup.$(date +%Y%m%d_%H%M%S)"

# Function to get component names from directory
# Get component names from directory
get_components() {
  local dir="$1"
  [[ ! -d "$dir" ]] && return
  # Using -print0 and xargs for better handling of filenames with spaces
  find "$dir" -maxdepth 1 -name "*.tsx" -type f -print0 |
    xargs -0 -I{} basename {} .tsx 2>/dev/null || true
}

# Create backup directory name with timestamp
create_backup_dir() {
  echo "${UI_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
}

# Get initial components
if [[ -d "$UI_DIR" ]]; then
  mapfile -t ui_components < <(get_components "$UI_DIR")
  component_count_before=${#ui_components[@]}
  print_msg "$BLUE" "Found $component_count_before components in $UI_DIR"
else
  ui_components=()
  component_count_before=0
fi

# Check if there are any components to process
if [[ $component_count_before -eq 0 ]]; then
  print_msg "$YELLOW" "Warning: No components found in $UI_DIR"
  read -p "Continue anyway? (y/n): " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# Countdown warning
echo
print_msg "$YELLOW" "WARNING: Creating a backup and completely wiping '$UI_DIR' in:"
for i in {5..1}; do
  echo "$i..."
  sleep 1
done
echo

# Create backup
BACKUP_DIR=$(create_backup_dir)
echo "Backing up UI components directory to $BACKUP_DIR..."
if [[ -d "$UI_DIR" ]]; then
  if cp -r "$UI_DIR" "$BACKUP_DIR"; then
    print_msg "$GREEN" "✅ Backup created successfully"
  else
    log_error "Failed to create backup"
  fi

  # Remove original directory to ensure clean install
  rm -rf "$UI_DIR"
fi

# Create empty component directory
mkdir -p "$UI_DIR"

# Install components with progress indicator
echo "Reinstalling UI components with shadcn@$SHADCN_BRANCH..."
total=${#ui_components[@]}
failed_components=()

# Check if there are any components to install
if [[ $total -eq 0 ]]; then
  print_msg "$YELLOW" "No components found to reinstall."
else
  # Function to install a single component
  install_component() {
    local component="$1"
    local branch="$2"

    printf "[%d/%d] Installing component: %s\n" $((i+1)) $total "$component"

    if ! run_package_runner shadcn@$branch add "$component" 2>/dev/null; then
      print_msg "$YELLOW" "⚠️ Failed to install component: $component"
      return 1
    fi
    return 0
  }

  for ((i=0; i<total; i++)); do
    component="${ui_components[$i]}"
    if ! install_component "$component" "$SHADCN_BRANCH"; then
      failed_components+=("$component")
    fi
  done
fi

# Get new components
if [[ -d "$UI_DIR" ]]; then
  mapfile -t new_ui_components < <(get_components "$UI_DIR")
  component_count_after=${#new_ui_components[@]}
else
  new_ui_components=()
  component_count_after=0
  log_error "Component directory disappeared during installation"
fi

# Report failed components
if [[ ${#failed_components[@]} -gt 0 ]]; then
  echo
  print_msg "$RED" "❌ The following components failed to install (${#failed_components[@]}):"
  printf -- "- %s\n" "${failed_components[@]}"
fi

# Function to cleanup backup directory
cleanup_backup() {
  echo "Removing backup directory..."
  if rm -rf "$BACKUP_DIR"; then
    print_msg "$GREEN" "✅ Backup directory removed"
    return 0
  else
    print_msg "$RED" "Failed to remove backup directory: $BACKUP_DIR"
    return 1
  fi
}

# Function to analyze component differences
analyze_components() {
  # Find and display missing components
  local missing_components=()
  for component in "${ui_components[@]}"; do
    if ! printf '%s\0' "${new_ui_components[@]}" | grep -Fxqz -- "$component"; then
      missing_components+=("$component")
    fi
  done

  # Find new components that weren't in original set
  local new_added_components=()
  for component in "${new_ui_components[@]}"; do
    if ! printf '%s\0' "${ui_components[@]}" | grep -Fxqz -- "$component"; then
      new_added_components+=("$component")
    fi
  done

  if [[ ${#missing_components[@]} -gt 0 ]]; then
    print_msg "$RED" "Components missing after reinstall (${#missing_components[@]}):"
    printf -- "- %s\n" "${missing_components[@]}"
  fi

  if [[ ${#new_added_components[@]} -gt 0 ]]; then
    print_msg "$YELLOW" "New components added (${#new_added_components[@]}):"
    printf -- "- %s\n" "${new_added_components[@]}"
  fi
}

# Compare results
echo
if [[ $component_count_before -eq $component_count_after ]]; then
  print_msg "$GREEN" "✅ Component count matches: $component_count_before components"

  if [[ "$AUTO_REMOVE" = true ]]; then
    cleanup_backup
  else
    read -p "Component counts match. Would you like to remove the backup? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      cleanup_backup
    else
      echo "Backup directory preserved: $BACKUP_DIR"
    fi
  fi
else
  print_msg "$YELLOW" "⚠️ Component count mismatch: $component_count_before before vs $component_count_after after"

  analyze_components

  echo -e "\nBackup location: $BACKUP_DIR"
fi

print_msg "$BLUE" "shadcn update process completed"
