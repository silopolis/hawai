#!/bin/bash

set -e #ux

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
source .env

./scripts/python_setup.sh "$@"

echo "-- Source shell config in case it's been updated"
source ~/.profile
echo "-- Activate Python virtual environment"
source .venv/bin/activate
echo "-- Source '.env' configuration file"
source .env

# TODO Add Docker setup from upstream repository

./scripts/docker_build_images.sh "$@"

./scripts/vagrant_setup.sh "$@"

echo "-- Boostrap Vagrant environment"
vagrant up --no-parallel
# vagrant up networks
# vagrant up admin1
# vagrant up maria1 --provision-with install-db
# vagrant up maria1 --provision-with secure-install
# vagrant up maria1 --provision-with database-setup
# vagrant up wpress1

## and go back
cd "$cwd"
