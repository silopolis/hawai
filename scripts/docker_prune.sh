#!/bin/bash

set -e #ux
shopt -s dotglob

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
# shellcheck source="../.env"
source .env

echo "-- Remove Docker containers"
#docker -D container prune -f
if [[ "$(docker container ls -q)" ]]; then
  docker rm "$(docker container ls -q)" -f
fi

if [[ ! "$*" =~ .*"--no-rebuild".* ]]; then
  echo "-- Remove Docker images"
  #docker -D image prune -f
  docker image rm "$(docker images -aq)" -f
fi

echo "-- Remove Docker networks"
#docker -D network prune -f
docker network rm "$(docker network ls |grep vagrant |cut -d' ' -f1)" -f

if [[ "$DOCKER_PRUNE_OPTS" =~ .*"--prune-cache".* ]]; then
  echo "-- Prune buildx cache"
  docker buildx prune -af
fi

## and go back
cd "$cwd"
