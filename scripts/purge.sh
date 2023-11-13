#!/bin/bash

set -e #ux
shopt -s dotglob

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
# shellcheck source="../.env"
source .env

scripts/vagrant_purge.sh "$@"

scripts/docker_prune.sh "$@"

scripts/data_purge.sh "$@"

scripts/python_purge.sh "$@"

## and go back
cd "$cwd"
