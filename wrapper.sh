#!/bin/bash
#
# Wrapper script for executing Nexirift utility scripts

# Exit immediately if a command exits with a non-zero status, export all variables
set -e
set -o allexport
set -o pipefail

# Define constants
UTILITY_SCRIPTS_DIR="utility-scripts"
MAX_ENV_SEARCH_DEPTH=5

# Get script directory using absolute path
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Source common utilities
if [[ -f "${SCRIPT_DIR}/common.sh" ]]; then
    source "${SCRIPT_DIR}/common.sh"
elif [[ -f "./${UTILITY_SCRIPTS_DIR}/common.sh" ]]; then
    source "./${UTILITY_SCRIPTS_DIR}/common.sh"
else
    RED='\033[0;31m'
    echo -e "${RED}Error: common.sh not found in ${UTILITY_SCRIPTS_DIR}${RESET}" >&2
    exit 1
fi

# Attempt to find and source .env in current and parent directories
SEARCH_DIR=$(pwd)
ENV_FOUND=false

echo "Searching for .env file..."
for ((i=0; i<=MAX_ENV_SEARCH_DEPTH; i++)); do
  ENV_FILE="${SEARCH_DIR}/.env"

  if [[ -f "$ENV_FILE" ]]; then
    if source "$ENV_FILE"; then
      echo -e "${GREEN}Found and sourced .env file from: $SEARCH_DIR${RESET}"
      ENV_FOUND=true
      break
    else
      echo -e "${RED}Error sourcing .env file from: $SEARCH_DIR${RESET}" >&2
    fi
  fi

  # Stop if we've reached the root directory
  [[ "$SEARCH_DIR" == "/" ]] && break

  # Move up one directory
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
done

# Warning if no .env file was found
if ! $ENV_FOUND; then
  echo -e "${YELLOW}Warning: No .env file found within $MAX_ENV_SEARCH_DEPTH parent directories.${RESET}" >&2
fi

# Check if a script name was provided
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Error: No script specified${RESET}" >&2
  echo "Usage: $0 <script-name> [arguments]" >&2
  exit 1
fi

# Try to find the script in multiple locations
SCRIPT_NAME="$1"
POSSIBLE_PATHS=(
  "$UTILITY_SCRIPTS_DIR/$SCRIPT_NAME"
  "$UTILITY_SCRIPTS_DIR/$SCRIPT_NAME.sh"
  "$SCRIPT_DIR/$SCRIPT_NAME"
  "$SCRIPT_DIR/$SCRIPT_NAME.sh"
)

SCRIPT_FOUND=false
for SCRIPT_PATH in "${POSSIBLE_PATHS[@]}"; do
  if [[ -f "$SCRIPT_PATH" ]]; then
    SCRIPT_FOUND=true
    break
  fi
done

if $SCRIPT_FOUND; then
  # Script exists
  if [[ ! -x "$SCRIPT_PATH" ]]; then
    echo -e "${YELLOW}Script found but not executable, attempting to set execute permission...${RESET}"
    if ! chmod +x "$SCRIPT_PATH"; then
      echo -e "${RED}Warning: Could not make script executable${RESET}" >&2
    fi
  fi

  # Print script information
  echo -e "${GREEN}Executing: ${SCRIPT_PATH}${RESET}"
  echo -e "${YELLOW}--- SCRIPT INIT ---${RESET}"

  # Execute the script with remaining arguments
  exec "$SCRIPT_PATH" "${@:2}"
else
  # No script found
  echo -e "${RED}Error: Script '$SCRIPT_NAME' not found in utility scripts directories${RESET}" >&2

  # List available scripts to help the user
  echo -e "\nAvailable scripts:"
  find "$UTILITY_SCRIPTS_DIR" -name "*.sh" -type f -exec basename {} .sh \; | sort
  exit 1
fi
