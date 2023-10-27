#!/bin/bash

# TODO Convert to buildx bake
set -e #ux
shopt -s extglob

## Record directory we are called from
cwd="$(pwd)"
## Change to Dockerfiles directory
cd "$(dirname "$0")/.."
source ".env"

if [[ -f "$DOCKER_DIR/$1.dockerfile" ]]; then
  docker buildx build $DOCKER_BUILD_OPTS \
    -t "$DOCKER_IMG_NAMESPACE/$1:$DOCKER_IMG_TAG" \
    -f "$DOCKER_DIR/$1.dockerfile" \
    .;
elif [[ "$1" == "--all" ]]; then
  echo "-- Build docker images"
  #for i in *.dockerfile; dependencies! do can't loop :/
  for i in base rsyslog mariadb nginx lep wordpress; do
    img=${i%.*}
    echo "-- Build '$img' docker image"
    docker buildx build $DOCKER_BUILD_OPTS \
      -t "$DOCKER_IMG_NAMESPACE/$img:$DOCKER_IMG_TAG" \
      -f "$DOCKER_DIR/$img.dockerfile" \
      .;
  done
else
  echo "EE $0: wrong argument. Pass image name or '--all'."
  exit 1
fi

cd "$cwd"
