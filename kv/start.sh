#!/usr/bin/env bash
#
# Start a Valkey (Redis) container for Nexirift key-value storage

# Exit on command errors and unset variables
set -o errexit
set -o nounset

# Navigate to project root
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR/../.."

KV_CONTAINER_NAME="nexirift-valkey"

if ! [ -x "$(command -v docker)" ]; then
  echo -e "${RED}Error: Docker is not installed. Please install docker and try again.${RESET}\nDocker install guide: https://docs.docker.com/engine/install/"
  exit 1
fi

# Check if Docker daemon is running
if ! docker info &>/dev/null; then
  echo -e "${RED}Error: Docker daemon is not running. Please start Docker and try again.${RESET}"
  exit 1
fi

if [ "$(docker ps -q -f name=$KV_CONTAINER_NAME)" ]; then
  echo -e "${GREEN}Key-value store container '$KV_CONTAINER_NAME' already running${RESET}"
  exit 0
fi

if [ "$(docker ps -q -a -f name=$KV_CONTAINER_NAME)" ]; then
  echo "Starting existing container..."
  if docker start "$KV_CONTAINER_NAME"; then
    echo -e "${GREEN}Existing key-value store container '$KV_CONTAINER_NAME' started${RESET}"
    exit 0
  else
    echo -e "${RED}Failed to start existing container. It might be corrupted.${RESET}"
    read -p "Would you like to remove and recreate it? (y/N): " -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo "Operation cancelled."
      exit 1
    fi
    docker rm -f "$KV_CONTAINER_NAME" || true
  fi
fi

# Import env variables from .env if it exists
if [ -f ".env" ]; then
  set -a
  source .env
else
  echo -e "${YELLOW}Warning: .env file not found. Using default settings.${RESET}"
fi

# Check if valkey image exists
IMAGE="valkey/valkey:8.0.2-alpine"
echo "Checking for Docker image: $IMAGE"
if ! docker image inspect "$IMAGE" &>/dev/null; then
  echo -e "${YELLOW}Docker image $IMAGE not found locally. Pulling...${RESET}"
  if ! docker pull "$IMAGE"; then
    echo -e "${RED}Failed to pull $IMAGE. Check your internet connection.${RESET}"
    exit 1
  fi
fi

# Start the container
echo "Starting Valkey container..."
if docker run -d \
  --name $KV_CONTAINER_NAME \
  -p 6379:6379 \
  --restart unless-stopped \
  $IMAGE; then
  echo -e "${GREEN}Key-value store container '$KV_CONTAINER_NAME' was successfully created${RESET}"
  echo -e "${GREEN}Valkey is now running on port 6379${RESET}"
else
  echo -e "${RED}Failed to start Valkey container. Check docker logs for more information.${RESET}"
  exit 1
fi
