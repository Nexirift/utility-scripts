#!/bin/bash
#
# Execute database commands in the @nexirift/db package

# Exit on command errors
set -o errexit

# Log messages
log_info() {
    echo "INFO: $1"
}

log_error() {
    echo "ERROR: $1" >&2
}

# Find node_modules directory and execute the command
log_info "Finding @nexirift/db package..."
NODE_MODULES_DIR=""

# Try to find node_modules in current directory or parent directories
current_dir=$(pwd)
MAX_DEPTH=10
DEPTH=0

while [[ "$current_dir" != "" && $DEPTH -lt $MAX_DEPTH ]]; do
    if [[ -d "$current_dir/node_modules" ]]; then
        NODE_MODULES_DIR="$current_dir/node_modules"
        break
    fi
    current_dir=${current_dir%/*}
    ((DEPTH++))
done

if [[ -z "$NODE_MODULES_DIR" ]]; then
    log_error "node_modules directory not found after searching $DEPTH directories"
    exit 1
fi

if [[ ! -d "$NODE_MODULES_DIR/@nexirift/db" ]]; then
    log_error "@nexirift/db not found in node_modules at $NODE_MODULES_DIR"
    log_info "Try running 'npm install' or equivalent to install dependencies"
    exit 1
fi

# Execute the command in the @nexirift/db directory
log_info "Found @nexirift/db at $NODE_MODULES_DIR/@nexirift/db"
cd "$NODE_MODULES_DIR/@nexirift/db"

# Check if input already starts with db:, otherwise prepend it
if [[ "$*" == db:* ]]; then
    CMD_ARG="$*"
else
    CMD_ARG="db:$*"
fi

log_info "Executing command: $CMD_ARG"

# Try with db: prefix first, then USER_INPUT with package manager, then directly
if command -v "$PACKAGE_MANAGER" &>/dev/null; then
    if $PACKAGE_MANAGER run "$CMD_ARG" 2>/dev/null; then
        log_info "Command executed successfully with db: prefix"
        exit 0
    elif $PACKAGE_MANAGER run "$@" 2>/dev/null; then
        log_info "Command executed successfully without db: prefix"
        exit 0
    else
        log_info "Package manager commands failed, attempting direct execution"
        exec "$@"
    fi
else
    log_error "Package manager not found. Please ensure it's installed and available in PATH"
    exit 1
fi
