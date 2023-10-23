#!/bin/bash

set -eux
shopt -s extglob

cwd="$(pwd)"
cd "$(dirname $0)"

echo "-- Build docker images"
for i in *.dockerfile; do
  img=${i%.*}
  echo "-- Build '$img' docker image"
  docker buildx build -t "silopolis:$img" -f "$img.dockerfile" .;
done

cd "$cwd"
