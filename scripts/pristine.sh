#!/bin/bash

set -e #ux
shopt -s dotglob

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
# shellcheck source="../.env"
source .env

scripts/purge.sh "$@"

scripts/bootstrap.sh "$@"

## and go back
cd "$cwd"
