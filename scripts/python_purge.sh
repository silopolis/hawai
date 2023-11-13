#!/bin/bash

set -e #ux
shopt -s dotglob

ARGS="$*"

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
# shellcheck source="../.env"
source .env

if [[ ! "$ARGS" =~ .*"--no-python-purge".* ]]; then
  echo "-- Purge Python virtual environment"
  rm -rf .venv
fi
## and go back
cd "$cwd"
