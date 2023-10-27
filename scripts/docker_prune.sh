#!/bin/bash

set -e #ux
shopt -s dotglob

source .env

echo "-- Remove Docker containers"
#docker -D container prune -f
docker rm "$(docker container ls -q)" -f
echo "-- Remove Docker images"
#docker -D image prune -f
docker image rm "$(docker images -aq)" -f
echo "-- Remove Docker networks"
#docker -D network prune -f
docker network rm "$(docker network ls |grep vagrant |cut -d' ' -f1)" -f
echo "-- Purge buildx cache"
docker buildx prune -af
