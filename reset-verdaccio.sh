#!/bin/bash
#
# Reset Verdaccio and clean up related caches

# Exit on command errors and unset variables
set -o errexit
set -o nounset

# Check if running in interactive mode and prompt for confirmation
if [ -t 0 ]; then
    echo -e "${YELLOW}WARNING: This will remove Verdaccio storage and package caches${RESET}"
    read -p "Are you sure you want to continue? (y/N): " -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

echo "Cleaning up caches and Verdaccio storage..."

# Remove lock files
if [ -f "bun.lock" ]; then
    rm bun.lock && echo "✓ Removed bun.lock"
else
    echo "- bun.lock not found, skipping"
fi

# Remove Bun cache
if [ -d ~/.bun/cache/install ]; then
    rm -rf ~/.bun/cache/install && echo "✓ Removed ~/.bun/cache/install"
else
    echo "- ~/.bun/cache/install not found, skipping"
fi

# Remove Verdaccio storage
if [ -d ~/.local/share/verdaccio/storage ]; then
    rm -rf ~/.local/share/verdaccio/storage && echo "✓ Removed ~/.local/share/verdaccio/storage"
else
    echo "- ~/.local/share/verdaccio/storage not found, skipping"
fi

echo -e "${GREEN}Verdaccio reset complete!${RESET}"
