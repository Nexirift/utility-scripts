#!/bin/bash

cd "$(dirname "$0")/../.."
docker exec -ti nexirift-valkey redis-cli flushall
