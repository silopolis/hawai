#!/bin/bash

# TODO Convert to buildx bake
set -e #ux
shopt -s extglob

cwd="$(pwd)"
# cd "$(dirname "$0")"
#DKR_OPTS="--no-cache --progress=plain"

echo "-- Build docker images"
cd "$DOKR_DIR"
for i in *.dockerfile; do
  img=${i%.*}
  echo "-- Build '$img' docker image"
  docker buildx build "$DKR_OPTS" -t "silopolis:$img" -f "$img.dockerfile" .;
done

cd "$cwd"
