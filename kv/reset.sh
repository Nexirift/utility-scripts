#!/bin/bash
#
# Reset the Nexirift key-value store by flushing all data

# Exit on command errors and unset variables
set -o errexit
set -o nounset

# Navigate to project root
cd "${SCRIPT_DIR}/../.."

# Check if we're in a terminal and prompt for confirmation
if [ -t 0 ]; then
    echo "WARNING: This will delete ALL data in the key-value store!"
    read -p "Are you sure you want to continue? (y/N): " -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# Check if Docker is running
if ! docker info &>/dev/null; then
    echo "Error: Docker is not running. Please start Docker and try again." >&2
    exit 1
fi

# Check if container exists
if ! docker ps -q -a -f name=nexirift-valkey &>/dev/null; then
    echo "Error: Key-value store container 'nexirift-valkey' not found." >&2
    echo "Please start the container first with: ./utility-scripts/kv/start.sh" >&2
    exit 1
fi

# Check if container is running
if ! docker ps -q -f name=nexirift-valkey &>/dev/null; then
    echo "Error: Container 'nexirift-valkey' is not running." >&2
    echo "Please start the container with: docker start nexirift-valkey" >&2
    exit 1
fi

echo "Flushing all data from key-value store..."
if docker exec -i nexirift-valkey redis-cli flushall; then
    echo "Key-value store reset completed successfully."
else
    echo "Error: Failed to reset key-value store." >&2
    exit 1
fi
