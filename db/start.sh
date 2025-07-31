#!/usr/bin/env bash
#
# Start a PostgreSQL database container for Nexirift

# Exit on command errors and unset variables
set -o errexit
set -o nounset

# Navigate to project root
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR/../../.."

DB_CONTAINER_NAME="nexirift-postgres"

if ! [ -x "$(command -v docker)" ]; then
  echo -e "${RED}Error: Docker is not installed. Please install docker and try again.${RESET}\nDocker install guide: https://docs.docker.com/engine/install/"
  exit 1
fi

# Check if Docker daemon is running
if ! docker info &>/dev/null; then
  echo -e "${RED}Error: Docker daemon is not running. Please start Docker and try again.${RESET}"
  exit 1
fi

if [ "$(docker ps -q -f name=$DB_CONTAINER_NAME)" ]; then
  echo "Database container '$DB_CONTAINER_NAME' already running"
  exit 0
fi

if [ "$(docker ps -q -a -f name=$DB_CONTAINER_NAME)" ]; then
  docker start "$DB_CONTAINER_NAME"
  echo "Existing database container '$DB_CONTAINER_NAME' started"
  exit 0
fi

# Check if DATABASE_URL is defined
if [ -z "${DATABASE_URL:-}" ]; then
  echo -e "${RED}Error: DATABASE_URL is not defined in .env file.${RESET}"
  exit 1
fi

# Parse connection details from DATABASE_URL
DB_PASSWORD=$(echo "$DATABASE_URL" | awk -F':' '{print $3}' | awk -F'@' '{print $1}')
DB_PORT=$(echo "$DATABASE_URL" | awk -F':' '{print $4}' | awk -F'\/' '{print $1}')

if [ "$DB_PASSWORD" = "password" ]; then
  echo "You are using the default database password"
  read -p "Should we generate a random password for you? [y/N]: " -r REPLY
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Please change the default password in the .env file and try again"
    exit 1
  fi
  # Generate a random URL-safe password
  DB_PASSWORD=$(openssl rand -base64 12 | tr '+/' '-_')
  sed -i -e "s#:password@#:$DB_PASSWORD@#" .env
fi

# Check if the required image exists
if ! docker image inspect postgres-wal2json &>/dev/null; then
  echo -e "${YELLOW}Warning: postgres-wal2json image not found. Attempting to use standard postgres image...${RESET}"
  POSTGRES_IMAGE="postgres:latest"
else
  POSTGRES_IMAGE="postgres-wal2json"
fi

echo "Starting PostgreSQL container..."
if docker run -d \
  --name $DB_CONTAINER_NAME \
  -e POSTGRES_USER="postgres" \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -e POSTGRES_DB=nexirift \
  -p "$DB_PORT":5432 \
  $POSTGRES_IMAGE; then
  echo -e "${GREEN}Database container '$DB_CONTAINER_NAME' was successfully created${RESET}"
else
  echo -e "${RED}Failed to start database container. Check docker logs for more information.${RESET}"
  exit 1
fi

echo -e "${GREEN}PostgreSQL is now running on port $DB_PORT${RESET}"
