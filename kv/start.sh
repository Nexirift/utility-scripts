#!/usr/bin/env bash

cd "$(dirname "$0")/../.."

KV_CONTAINER_NAME="nexirift-valkey"

if ! [ -x "$(command -v docker)" ]; then
  echo -e "Docker is not installed. Please install docker and try again.\nDocker install guide: https://docs.docker.com/engine/install/"
  exit 1
fi

if [ "$(docker ps -q -f name=$KV_CONTAINER_NAME)" ]; then
  echo "Database container '$KV_CONTAINER_NAME' already running"
  exit 0
fi

if [ "$(docker ps -q -a -f name=$KV_CONTAINER_NAME)" ]; then
  docker start "$KV_CONTAINER_NAME"
  echo "Existing database container '$KV_CONTAINER_NAME' started"
  exit 0
fi

# import env variables from .env
set -a
source .env

docker run -d \
  --name $KV_CONTAINER_NAME \
  -p 6379:6379 \
  valkey/valkey:8.0.2-alpine && echo "Key-value store container '$KV_CONTAINER_NAME' was successfully created"
