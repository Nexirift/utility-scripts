#!/bin/bash
#
# Common utilities and configuration for Nexirift scripts
# This script is intended to be sourced by other scripts

# Exit on command errors and unset variables
set -o errexit
set -o nounset

# Define colors for better output readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Check if package manager/runner are already set in environment
if [[ -n "${PACKAGE_MANAGER:-}" ]] && [[ -n "${PACKAGE_RUNNER:-}" ]]; then
    echo "Using environment-defined package manager ($PACKAGE_MANAGER) and package runner ($PACKAGE_RUNNER)."
else
    # Check for package managers in preferred order
    if command -v pnpm &> /dev/null; then
        PACKAGE_MANAGER="pnpm"
        PACKAGE_RUNNER="pnpx"
    elif command -v yarn &> /dev/null; then
        PACKAGE_MANAGER="yarn"
        PACKAGE_RUNNER="yarn dlx"
    elif command -v npm &> /dev/null; then
        PACKAGE_MANAGER="npm"
        PACKAGE_RUNNER="npx"
    elif command -v bun &> /dev/null; then
        PACKAGE_MANAGER="bun"
        PACKAGE_RUNNER="bunx"
        echo "NOTICE: Bun detected - While functional, the Nexirift team recommends pnpm since we have encountered issues with Bun in the past. If you encounter issues, please verify they can be reproduced with pnpm before reporting bugs to distinguish between Bun-specific problems and actual bugs."
    else
        echo "Error: No supported package manager found."
        exit 1
    fi

    echo "Using $PACKAGE_MANAGER for package management and $PACKAGE_RUNNER for package execution."
fi

# Print colored message to stderr
print_error() {
    local RED='\033[0;31m'
    local RESET='\033[0m'
    echo -e "${RED}Error: $1${RESET}" >&2
}

# Print warning message
print_warning() {
    local YELLOW='\033[0;33m'
    local RESET='\033[0m'
    echo -e "${YELLOW}Warning: $1${RESET}"
}

# Print success message
print_success() {
    local GREEN='\033[0;32m'
    local RESET='\033[0m'
    echo -e "${GREEN}$1${RESET}"
}

# Function to run package manager commands with error handling
run_package_manager() {
    local cmd_output
    if ! cmd_output=$($PACKAGE_MANAGER "$@" 2>&1); then
        print_error "Package manager command failed with exit code $?"
        echo "$cmd_output" >&2
        return 1
    fi
    return 0
}

# Function to run executable packages with error handling
run_package_runner() {
    local cmd_output
    if ! cmd_output=$($PACKAGE_RUNNER "$@" 2>&1); then
        print_error "Package runner command failed with exit code $?"
        echo "$cmd_output" >&2
        return 1
    fi
    return 0
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}
