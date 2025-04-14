#!/bin/bash

set -e

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

# Default values
SHADCN_BRANCH="latest"
UI_DIR="src/components/ui"
AUTO_REMOVE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--branch)
      if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo "Error: Missing value for --branch option"
        exit 1
      fi
      SHADCN_BRANCH="$2"
      if [[ "$SHADCN_BRANCH" != "latest" && "$SHADCN_BRANCH" != "canary" ]]; then
        echo "Error: Branch must be 'latest' or 'canary'"
        exit 1
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
  echo "Error: UI directory '$UI_DIR' not found!"
  exit 1
fi

BACKUP_DIR="${UI_DIR}.backup.$(date +%Y%m%d_%H%M%S)"

# Function to get component names from directory
get_components() {
  local dir="$1"
  [[ ! -d "$dir" ]] && return
  find "$dir" -maxdepth 1 -name "*.tsx" -type f -exec basename {} .tsx \;
}

# Get initial components
mapfile -t ui_components < <(get_components "$UI_DIR")
component_count_before=${#ui_components[@]}

# Create backup
echo "Backing up UI components directory to $BACKUP_DIR..."
if cp -r "$UI_DIR" "$BACKUP_DIR"; then
  echo "✅ Backup created successfully"
else
  echo "❌ Failed to create backup"
  exit 1
fi

# Remove original directory to ensure clean install
rm -rf "$UI_DIR"
mkdir -p "$UI_DIR"

# Install components with progress indicator
echo "Reinstalling UI components with shadcn@$SHADCN_BRANCH..."
total=${#ui_components[@]}
failed_components=()

for ((i=0; i<total; i++)); do
  component="${ui_components[$i]}"
  printf "[%d/%d] Installing component: %s\n" $((i+1)) $total "$component"

  if ! bunx --bun shadcn@$SHADCN_BRANCH add "$component"; then
    echo "⚠️ Failed to install component: $component"
    failed_components+=("$component")
  fi
done

# Get new components
mapfile -t new_ui_components < <(get_components "$UI_DIR")
component_count_after=${#new_ui_components[@]}

# Report failed components
if [[ ${#failed_components[@]} -gt 0 ]]; then
  echo -e "\n❌ The following components failed to install:"
  printf -- "- %s\n" "${failed_components[@]}"
fi

# Compare results
if [[ $component_count_before -eq $component_count_after ]]; then
  echo -e "\n✅ Component count matches: $component_count_before components"

  if [[ "$AUTO_REMOVE" = true ]]; then
    echo "Auto-removing backup directory..."
    rm -rf "$BACKUP_DIR"
    echo "✅ Backup directory removed"
  else
    read -p "Component counts match. Would you like to remove the backup? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -rf "$BACKUP_DIR"
      echo "✅ Backup directory removed"
    else
      echo "Backup directory preserved: $BACKUP_DIR"
    fi
  fi
else
  echo -e "\n⚠️ Component count mismatch: $component_count_before before vs $component_count_after after"

  # Find and display missing components
  missing_components=()
  for component in "${ui_components[@]}"; do
    if ! [[ " ${new_ui_components[*]} " =~ " ${component} " ]]; then
      missing_components+=("$component")
    fi
  done

  echo "Components missing after reinstall (${#missing_components[@]}):"
  printf "- %s\n" "${missing_components[@]}"
  echo -e "\nBackup location: $BACKUP_DIR"
fi
