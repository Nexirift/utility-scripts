#!/bin/bash
#
# Reset the Nexirift database by removing migrations and recreating the database

# Exit on command errors and unset variables
set -o errexit
set -o nounset

# Navigate to project root
cd "${SCRIPT_DIR}/../.."

# Check if we're in a terminal and prompt for confirmation
if [ -t 0 ]; then
    echo "WARNING: This will reset the database and delete all migrations!"
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
if ! docker ps -q -a -f name=nexirift-postgres &>/dev/null; then
    echo "Error: Database container 'nexirift-postgres' not found." >&2
    echo "Please start the database container first with: ./utility-scripts/db/start.sh" >&2
    exit 1
fi

echo "Removing migration files..."
rm -f migrations/*.sql
rm -rf migrations/meta

echo "Dropping database..."
if ! docker exec -i nexirift-postgres dropdb -U postgres -f 'nexirift'; then
    echo "Warning: Failed to drop database. It might not exist yet." >&2
fi

echo "Creating database..."
docker exec -i nexirift-postgres createdb -U postgres 'nexirift'

echo "Database reset completed successfully."
